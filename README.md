# I_LOVE_IKEA_SHINY_APP

This is [the Ikea hackaton](http://hackathon.ikea.com/) R Shiny app that we (I, Jos van Dongen and Thomas van Dongen) created on December 7,8,9 of 2017. The instructions for the app are quite simple, see images below. Our 3 minute pitch in [pdf](ILoveIkea.pdf) is also in this repo. 


The app helps IKEA customers to look for Ikea products by means of image search. Take a picture, upload it and you will get the top matching IKEA products back.


<p align="center">
  <img src="ikeaphoneapp1.png" width="350"/>
</p>

<p align="center">
  <img src="ikeaphoneapp2.png" width="350"/>
</p>


So what steps are taken to get this app working?

1. Scrape IKEA website using R package rvest for product images, in total we have around 9000 scraped IKEA images. The R code to scrape Ikea is also available on GitHub, see me [ikeaScraper](https://github.com/longhowlam/ikeaScraper) library.

2. Use R Keras to put all images through a pretrained [VGG16 network](https://www.pyimagesearch.com/2017/03/20/imagenet-vggnet-resnet-inception-xception-keras/) from which the top layers are removed. Each image is now a tensor, that we flatten to a vector (25.088 dimensional vector). So we end up with a 9000 by 25088 matrix.

<p align="center">
  <img src="vgg16_.png" width="450"/>
</p>

3. For a new image: put it trough the same network, and flatten this to a 25088 dimensional vector as well. Now determine for that image the top 10 closest IKEA images, using for example cosine similarity.

4. Present the reults in a Shiny App.

5. A live running shiny app can be found [here](http://178.62.211.224:3838/sample-apps/I_LOVE_IKEA_SHINY_APP/), which I will probably close down by the end of 2017 because it costs me some money to keep up a droplet on Digital Ocean :-)


