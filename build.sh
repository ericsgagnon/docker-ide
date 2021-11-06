#!/bin/bash

VERSION=$1

image_name=ide
build_tag="${VERSION:=dev}"
echo "Build Tag: ${build_tag}"


docker build --pull --no-cache=true -t ericsgagnon/${image_name}:${build_tag} --build-arg=VERSION=${build_tag} -f Dockerfile . 
#docker build --pull -t ericsgagnon/${image_name}:${build_tag}  -f Dockerfile . 
build_exit_code=$?

if [[ $build_exit_code -ne 0 ]] ; then
   echo "build failed"
   exit 1
fi

echo "docker push ericsgagnon/${image_name}:${build_tag}"
docker push ericsgagnon/${image_name}:${build_tag}
push_exit_code=$?
if [[ ${push_exit_code} -ne 0 ]] ; then
  echo "push failed"
  exit 1
fi
export TIME_TAG=$(date -u +%Y%m)
echo "docker tag ericsgagnon/${image_name}:${build_tag} ericsgagnon/${image_name}:${TIME_TAG}"
docker tag ericsgagnon/${image_name}:${build_tag} ericsgagnon/${image_name}:${TIME_TAG}
echo "docker push ericsgagnon/${image_name}:${TIME_TAG}"
docker push ericsgagnon/${image_name}:${TIME_TAG}

echo "test the image by:"
echo "docker run -d -i -t --gpus all -p 80:80 --name ${image_name} ericsgagnon/${image_name}:${build_tag}"
echo "sleep 10 && docker logs ${image_name} "
echo "docker exec -i -t ${image_name} /bin/bash"
echo "# cleanup"
echo "docker rm -fv ${image_name}"


