shared: *.o
	gcc -L. -shared -o libcrlibm.dylib *.o scs_lib/*.o
