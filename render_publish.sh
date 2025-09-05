#!/bin/sh
commitmsg=$1
rm -r /Users/tomkom/Dropbox/MyDocs/Teaching/UoM_IE/GEOM90008_SpatialDataManagement/book_SDM/spatialdatamanagement/public/
mkdir /Users/tomkom/Dropbox/MyDocs/Teaching/UoM_IE/GEOM90008_SpatialDataManagement/book_SDM/spatialdatamanagement/public/
cp -r ./docs/ /Users/tomkom/Dropbox/MyDocs/Teaching/UoM_IE/GEOM90008_SpatialDataManagement/book_SDM/spatialdatamanagement/public/
git -C "/Users/tomkom/Dropbox/MyDocs/Teaching/UoM_IE/GEOM90008_SpatialDataManagement/book_SDM/spatialdatamanagement" add .
git -C "/Users/tomkom/Dropbox/MyDocs/Teaching/UoM_IE/GEOM90008_SpatialDataManagement/book_SDM/spatialdatamanagement" commit -am "$commitmsg"
git -C "/Users/tomkom/Dropbox/MyDocs/Teaching/UoM_IE/GEOM90008_SpatialDataManagement/book_SDM/spatialdatamanagement" push