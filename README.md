# arte29

 <img src="https://github.com/leeseomin/arte29/blob/main/out/IMG_2945mon7cpu1_cake.png" width="2000">

### Dependency install on ubuntu 20.04 


```
 # parallel install
 
 sudo apt install parallel
 
 
   #  gimp gmic install

sudo add-apt-repository ppa:otto-kesselgulasch/gimp-edge

sudo apt-get update

sudo apt-get install gmic gimp-gmic


 #   imagemagick install

sudo apt install graphicsmagick-imagemagick-compat

sudo apt install imagemagick-6.q16


 #  Gmic update filters (follow the link)
 
https://telegra.ph/Gmic-update-filters-07-26

```



### Install

```

git clone https://github.com/leeseomin/arte29

cd arte29

mkdir s{1..25}

-----------------------------------------

### Change the location of the following file to suit your environment in main.sh ###

/home/lee/arte29/logo/c.png  =>

/home/yourlogID/arte29/logo/c.png


```

### Usage
```

input images folder : s ,   result folder : s25


bash main.sh   

```




###  Results



### input image1
 <img src="https://github.com/leeseomin/arte29/blob/main/s/IMG_2945.png" width="500">
 
### output image1
 <img src="https://github.com/leeseomin/arte29/blob/main/out/IMG_2945mon7cpu1_cake.png" width="2000">
 <img src="https://github.com/leeseomin/arte29/blob/main/out/IMG_2945mon7cpu1_cake_cartesian30.png" width="2000">


### input image2
 <img src="https://github.com/leeseomin/arte29/blob/main/s/IMG_1716.png" width="500">
 
### output image2
 <img src="https://github.com/leeseomin/arte29/blob/main/out/IMG_1716mon7cpu1_cake.png" width="2000">
 <img src="https://github.com/leeseomin/arte29/blob/main/out/IMG_1716mon7cpu1.png" width="2000">




 
 
 
### make animated png result
```
ffmpeg -framerate 1 -pattern_type glob -i '*.png' \
  -c:v libx264 out.mp4
  
  
ffmpeg -i out.mp4 -plays 0  apngout.apng
  
```  
  
  

### License

This repo is made freely available to academic and non-academic entities for non-commercial purposes such as academic research, teaching, scientific publications. Permission is granted to use the arte29 given that you agree to my license terms. Regarding the request for commercial use, please contact me via email (leeseomin@gmail.com)



###  Author

LEE SEOMIN
