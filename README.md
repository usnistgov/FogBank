# FogBank
Single Cell Segmentation

***

Welcome to **FogBank** - the National Institute of Standards and Technology's 2D Single Cell Segmentation application, developed by the Information Technology Laboratory-Software and Systems Division at NIST Gaithersburg. 

The separation of touching cells in microscopy images is critical for the counting, identification and measurement of individual cells. Segmentation methods based on morphological watersheds are the current state-of-the-art for cell separation. However, over-segmentation of morphological watersheds is a major problem because of the high level of noise in microscopy cell images. We present a new segmentation method called FogBank that accurately separates cells when they are confluent and touching each other. Figure 1 illustrates segmentation outcomes for a set of algorithmic parameters.

![FogBank Summary Figure](../../wiki/images/fogbank_segmentation_figure.png)
_Figure 1: Geodesic region growing for single cell edge detection starting from seed points and following the histogram percentile quantization of intensities in grayscale image and geodesic mask constraint. Images 1 to 6 are the masks generated from the 10th, 30th, 50th, 70th, 90th and 100th percentiles_

## Description

This technique has been successfully applied to phase contrast, bright field, and fluorescence microscopy images, as well as to binary images. FogBank method is based on the morphological watershed principles with two new features to improve the accuracy of related segmentation methods. First, to eliminate the pixel intensity noise that causes over-segmentation, our new method uses histogram binning to quantize the pixel intensities or pixel intensity gradients. We grow watersheds in increments of multiple pixel intensities rather than single intensities. Second, our method uses a geodesic distance mask derived from raw images to incorporate the shapes of individual cells, in contrast to the more linear cell edges that other watershed-like algorithms produce. The segmentation technique is fully automated and does not require any manual region seeding.

***

# Quick Navigation

#### - [About FogBank](https://isg.nist.gov/deepzoomweb/resources/csmet/pages/fogbank_segmentation/fogbank_segmentation.html;jsessionid=1F7959DC4F05317B597BDE3E50A8BD5A)
#### - [Wiki](https://github.com/usnistgov/FogBank/wiki)

## Sample Data Sets

We have an example dataset of grayscale and resulting segmented images. The segmentation parameters are included. 

The dataset can be downloaded from the following link:

[Fogbank_Test_Images.zip ~ 10 MB](../../wiki/testdata/Fogbank_Test_Images.zip)

