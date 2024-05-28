clean:
	touch star.log
	touch star.wlf
	touch transcript
	if [ ! -d "work/" ]; then  \
	    mkdir "work/";  \
	fi 
	rm transcript
	rm *.log
	rm *.wlf
	rm -r work/

compile:
	./runsim.sh

wave:
	./viewave.sh
