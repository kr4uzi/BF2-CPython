Drop-in replacement for Battlefield 2's python.
Several build errors of the original (parent fork) repository prevented me from building the dice_py.dll.

build.bat automatically detects visual studio and downloads + patches + builds python 2.7.18

The initial motivation for this project was to test my own bf2 python debuggers multi-threading capabilities and wether or not,
Visual Studio Code's python debugger (debugpy) would launch.
For some reason I wasn't able to connect to the session, maybe a older Python Plugin for VSCode needs to be installed. Since my down
bf2 python debugger runs already, I didn't further investigate.

If you want to get the "official" debugpy running, here is what I did:
0.) Build & install dice_py.dll and pylib-2.3.4.zip (create backup of original files of course)
1.) Have a local Python 2.7 installation
2.) Download the last py2 compatible debugpy: https://pypi.org/project/debugpy/1.5.1/#files
3.) Install C:\python27\python.exe -m pip install <downloaded debugpy>.whl
4.) Copy C:\Python27\Lib\site-packages\debugpy to C:\Battlefield 2\python\debugpy
5.) Copy all *.pyd files from <this repo>\python-2.7.18\PCbuild\win32\*.pyd to C:\Battlefield 2\python
6.) Modify C:\Battlefield 2\python\bf2\__init__.py
```python
import host
import sys
# debugpy begin
sys.path.insert(0, 'python') # this will allow debugpy to be loaded (which itself needs the *.pyd files in the /python folder)
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()
# debugpy end

from bf2.Timer import Time
#...
```


I haven't yet found a way to statically link and load all dynamically loaded modules (*.pyd).
The standard bf2 python (2.3.4) is built with the _socket module added to the PyImport_Inittab (config.c)
