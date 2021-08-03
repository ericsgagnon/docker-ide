#!/bin/bash

VERSION=$1

build_tag="${VERSION:=dev}"
echo "Build Tag: ${build_tag}"


#docker build --pull --no-cache=true -t ericsgagnon/ide:${build_tag}  -f Dockerfile . 
docker build --pull -t ericsgagnon/ide:${build_tag}  -f Dockerfile . 
build_exit_code=$?

if [[ $build_exit_code -ne 0 ]] ; then
   echo "build failed"
   exit 1
fi

# echo "docker push ericsgagnon/ide:${build_tag}"
# docker push ericsgagnon/ide:${build_tag}
# push_exit_code=$?
# if [[ ${push_exit_code} -ne 0 ]] ; then
#   echo "push failed"
#   exit 1
# fi

echo "test the image by:"
echo "docker run -d -i -t --gpus all -p 80:80 --name ide ericsgagnon/ide:${build_tag}"
echo "sleep 10 && docker logs ide "
echo "docker exec -i -t ide /bin/bash"
echo "# cleanup"
echo "docker rm -fv ide"
