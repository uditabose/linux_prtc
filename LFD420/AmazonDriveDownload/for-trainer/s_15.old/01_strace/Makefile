### Automatic Makefile generation by 'genmake' script        ####
### Copyright, Jerry Cooperstein, coop@linuxfoundation.org 2/2003 - 1/2011 ####
### License: GPLv2 ###

allofit:  userprogs

userprogs:
	@$(MAKE) \
		CFLAGS="-O2 -Wall -pedantic" \
		LDFLAGS="-lpthread -lrt" \
	 unnamed_sem_wait

clean:
	rm -rf  unnamed_sem_wait 
