Sometimes we need to find the duplicate files in our file system, or inside a specific folder. In this tutorial we are going to code a Python script to do this. This script works in Python 3.x.

The program is going to receive a folder or a list of folders to scan, then is going to traverse the directories given and find the duplicated files in the folders.

This program is going to compute a hash for every file, allowing us to find duplicated files even though their names are different. All of the files that we find are going to be stored in a dictionary, with the hash as the key, and the path to the file as the value: { hash: [list of paths] }.

