import os
from qgis.core import *
import qgis.utils
distance_list_all = []
feature_distances_from_start = []
#I create a list with all the possible names for structural regions
cities_list = ['wesel','Hünxe','Haltern am','Köln','Düren','Aagen','Dortmund','Dinslaken','Essen','Haan','Wuppertal','Hagen','Hamm','Osnabruk','Düsseldorf','Netherlands','Eversvinkel','Gievenveck','Telgte','Coerde','Wolbeck','Bremen','Emden','Steinfurt','Havixbeck','Ascheberg','Amelsburen','Dülmen','Roxel','Senden','Hannover','Crops field','Warendorf','HerzeClarhol','Rheda-Wieden','Sande','Elsen','Paderborn','Wasserski Se','Kamen','Ruhrgebiet','Siegen','Krombach','Olpe','Horstmar']
#Iterate the 34 particpants to find polygons and lines. I do this three times, one for each type of route. Example: Homecity = intercity route
for i in range(1,34):
    polygons = os.path.join(r"C:\Users\Vanesa\Desktop\MAPS THESIS\Participant"+str(i+1)+r"\Home city\polygons.shp")
    polygons_layers = iface.addVectorLayer(polygons, "shape:", "ogr")
    lines = os.path.join(r"C:\Users\Vanesa\Desktop\MAPS THESIS\Participant"+str(i+1)+r"\Home city\streets_dissolved.shp");
    lines_layer = iface.addVectorLayer(lines, "shape:", "ogr")
    if not polygons_layers:
        print("Polygon failed to load!");
    elif not lines_layer:
        print("Lines failed to load!");
    if(lines_layer and polygons_layers):
        features_polygons = polygons_layers.getFeatures();
        count = 0;
        features_lines = lines_layer.getFeatures();
        #print(features_lines);
        line_ = "";
        line_length = 1;
        for feature in features_lines:
            geom = feature.geometry()
            line_length = geom.length();
            line_=feature;
        line_= line_.geometry();
        #print(line_);
        distance_list = []
        #If the id of the polygon is in the list, create centroid, locate this on the normalized line length. Iterate and repite this in all the polygons, then append all the distance to a list.
        for feature in features_polygons:
        if feature[osm.id] in cities_list:
                centroid = feature.geometry().centroid();
                distance_from_start = line_.lineLocatePoint(centroid);
                distance_list.append(distance_from_start/line_length * 100)
                feature_distances_from_start.append(distance_from_start);  
        distance_list_all.append(distance_list);
print(distance_list_all)
print(feature_distances_from_start)
