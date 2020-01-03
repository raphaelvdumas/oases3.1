# OASES 3.1 - Installation Guide

[OASES](https://tlo.mit.edu/technologies/oases-software-modeling-seismo-acoustic-propagation-horizontally-stratified-waveguides) is a general purpose computer code made by the [Massachusetts Institute of Technology](http://www.mit.edu/) for modeling seismo-acoustic propagation in horizontally stratified waveguides using wavenumber integration in combination with the Direct Global Matrix solution technique.

As I found myself in many difficulties during the installation of this software, this repository contains a full friendly installation guide to install OASES 3.1 on Windows 10.

The oases-public zip file given in this repository is different from the source oases-public found [here](http://lamss.mit.edu/lamss/tars/oases-public.tgz). 
The following modifications have been made : 
* removed the paroases-src folder and changed CMakeLists accordingly,
* changed CMakeLists of bin folder as rdoasp and rdoast doesn't come with this free version of OASES. 

**Sofwares installed:**
* [Ubuntu application](https://www.microsoft.com/en-us/p/ubuntu/9nblggh4msv6?activetab=pivot:overviewtab) from the Microsoft Store made by [Canonical](https://canonical.com/) Group Limited.

* [VcXsrv](https://sourceforge.net/projects/vcxsrv/) to handle the graphical interface between the Ubuntu application and Windows 10.

**Dependencies of OASES 3.1:** 
cmake, gcc, gfortran, csh, libx11-dev

_Last successful installation: december 14, 2019_
