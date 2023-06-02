/*
	gcc transpile.c -o transpiler.exe
	.\transpiler.exe -gcc
	.\transpiler.exe -tcc
	
	Produces the executable test.exe
	Which will print hello world
*/

#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[static 1]) {
	// fp can also be stdout for debugging purposes.
	FILE *fp = stdout;

    char outfile[] = "test.exe";

    if (argc > 1) {
        char outcmd[80];

       	// Open a pipe to the backend: E.g.
        if (strcmp(argv[1], "-tcc") == 0) {
            printf("Using TCC\n");
            snprintf(outcmd, sizeof outcmd, "tcc -o %s -", outfile);
            fp = popen(outcmd, "w");
        } else if (strcmp(argv[1], "-gcc") == 0) {
            printf("Using GCC\n");
            snprintf(outcmd, sizeof outcmd, "gcc -fwhole-program -o %s -x c++ -", outfile);
            fp = popen(outcmd, "w");
        }
    }

	// TODO: Walk AST or IR and get them to output their template
	// ast->outputC(fp);

    // A rough examples of what outputC might look like for each node type
    void codeBlock(FILE* fp) {
        fprintf(fp, "printf(\"hello, world\");\n");
    }

    void procNode(FILE* fp) {
        // Output a template with fprintf e.g. A procedure node might do -
        char proctype[] = "int";
        char procname[] = "main";
        fprintf(fp, "#include <stdio.h>\n%s %s() {\n", proctype, procname);
        codeBlock(fp);
        fprintf(fp, "}\n");
    }
	
    procNode(fp);

	fclose(fp);
	return 0;
}