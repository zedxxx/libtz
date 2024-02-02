
set shp=".\tz-border\combined-shapefile.shp"

set root=".\"
set p=15

shp2pas --shp=%shp% --out-kml="%root%kml\" --precision=%p%
shp2pas --shp=%shp% --out-pas="%root%pas\" --precision=%p%
