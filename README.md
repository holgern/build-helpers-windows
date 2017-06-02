Batch script to download and build libboost (using Visual Studio compiler)

```
Please keep in mind compiling Boost library takes a very long time.
```

**Usage**:

1. Clone or download this repo https://github.com/holgern/build-helpers-windows/archive/master.zip

2. Open command prompt and cd to `xxx/build-helpers-windows/build_boost`

3. Set path to compiler if necesasry
```
set PATH=C:\Qt\Tools\mingw530_32\bin;%PATH%;
```
3. Run this command for building:
```
build.bat [all/static/shared] [32/64] [msvc/gcc]
```
for example for shared 64 bit and msvc
```
build.bat shared 32 msvc
```
It is also possible to specifiy the visual studio version
```
build.bat shared 32 msvc-14.0
```

**Third-party**:

This program is using third party tools:

http://sourceforge.net/projects/unxutils/files/unxutils/current/

http://www.7-zip.org/download.html

http://sourceforge.net/projects/videlibri/files/Xidel/

https://cmake.org/download/