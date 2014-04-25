#Temporary
=========

##Summary
This app monitors a custom folder for contained files/folders with names contain a number. The first number detected in the foldername is the number of days the folder remains "alive" after it's creation date. If it exceeds it's lifetime, the folder/file will be deleted.

##tl;dr
Let's asume you want to save some data for a couple of days (for whatever reason). You could use the ```/tmp``` directory, but the folder is erased after each reboot, even after a crash. with Temporary enabled, you can put the number of days the folder should remain on your hd into the folder name. If their time is due, the respective folder will be deleted/


##background
I often create new xcode-projects for testing purposes, but sometimes the apps evolve into something usefull. Then something aweful happens and my macbook reboots. My ```/tmp``` folder is cleaned and everything is gone. The alternative is to create folders like ```delete me``` where you forget to delete them at all. Let's say I want to store some files for 3 days. I create a folder with the name ```3_somefiles``` and put it into my own ```local_tmp``` directory. With __Temporary__ running, the folder ```3_somefiles``` will be deleted 3 days after it;s creation.
