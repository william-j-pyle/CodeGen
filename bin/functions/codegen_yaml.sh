#!/bin/bash

function parse_yaml2 {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\057') as=$(echo @ | tr @ '\058')
   sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\- \($w\)$s:$s\(.*\)$s\$|  \1$as$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1
}

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034') as=$(echo @ | tr @ '\058')
   sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\- \($w\)$s:$s\(.*\)$s\$|  \1$fs\2$fs\3$fs\2|p" \
      -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3$fs|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3$fs|p" $1 |
      awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {
         delete vname[i]
         delete varray[i]
      }
      }
      if (length($3) > 0) {
         pvn="";
         darray="";
         if(length($4) > 0 ){
            for (i=0; i<indent-1; i++) {
               if(length(vname[i])>0){
                  pvn=(pvn)(vname[i])("_")
               }
            }
            varray[indent]+=1;
            printf("%s%s%s=\"%s\";\n", "'$prefix'",pvn, "count", varray[indent]);
         }
         vn=""; for (i=0; i<indent; i++) {
            if(varray[i+1]>0){
               darray=("[")(varray[i+1])("]");
            }
            if(length(vname[i])>0){
              vn=(vn)(vname[i])("_")
            }
         }
         if ($3 == "UNSET") {
           printf("unset \"%s%s%s\";\n", "'$prefix'",vn, $2);           
         } else {
           printf("%s%s%s%s=\"%s\";\n", "'$prefix'",vn, $2,darray, $3);
         }
      }
   }'
}

function parse_yaml_orig {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
      awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         if ($3 == "UNSET") {
           printf("unset \"%s%s%s\";\n", "'$prefix'",vn, $2);           
         } else {
           printf("%s%s%s=\"%s\";\n", "'$prefix'",vn, $2, $3);
         }
      }
   }'
}
