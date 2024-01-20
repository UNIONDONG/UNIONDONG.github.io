#!/bin/bash

BLOG_DIR=/home/donge/WorkSpace/uniondong.github.io
COMMON_POST_TEMPLATE="common_post"
DRAINAGE_POST_TEMPLATE="drainage"

function weight_adjust()
{
	CONTENT_DIR=$1
	CONTENT_NAME=$2
	if [ -z "${CONTENT_DIR}" ]; then
        echo "please input content dir"
    fi

	if [ -z "${CONTENT_NAME}" ]; then
        echo "please input content name"
    fi

	if [ -f ${CONTENT_DIR}/${CONTENT_NAME}.md ]; then
		weight=$(grep -rn "weight" "${CONTENT_DIR}" | wc -l)
		echo "weight adjust: $((weight - 1))"
		sed -i "s/weight: 1/weight: $((weight - 1))/g" ${CONTENT_DIR}/${CONTENT_NAME}.md
	fi
}

function post_common_article()
{
	CONTENT_DIR=$1
	CONTENT_NAME=$2
	if [ -z "${CONTENT_DIR}" ]; then
        echo "please input content dir"
    fi

	if [ -z "${CONTENT_NAME}" ]; then
        echo "please input content name"
    fi

	if [ ! -d ${CONTENT_DIR} ]; then
		mkdir -p ${CONTENT_DIR}
	fi

	echo "hugo new -k $COMMON_POST_TEMPLATE ${CONTENT_DIR}/${CONTENT_NAME}.md"
	hugo new -k $COMMON_POST_TEMPLATE ${CONTENT_DIR}/${CONTENT_NAME}.md

	weight_adjust "$CONTENT_DIR" "$CONTENT_NAME"
}

function post_drainage_article()
{
	CONTENT_DIR=$1
	CONTENT_NAME=$2
	if [ -z "${CONTENT_DIR}" ]; then
        echo "please input content dir"
    fi

	if [ -z "${CONTENT_NAME}" ]; then
        echo "please input content name"
    fi

	if [ ! -d ${CONTENT_DIR} ]; then
		mkdir -p ${CONTENT_DIR}
	fi

	echo "hugo new -k $DRAINAGE_POST_TEMPLATE ${CONTENT_DIR}/${CONTENT_NAME}.md"
	hugo new -k $DRAINAGE_POST_TEMPLATE ${CONTENT_DIR}/${CONTENT_NAME}.md

	weight_adjust "$CONTENT_DIR" "$CONTENT_NAME"
}

function build_hugo_and_push()
{
	echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
	# Build the project.
	hugo 			# build hugo
	cd content
	git add .
	cd ../
	# Go To Public folder
	cd public
	# Add changes to git.
	git add .
	cd ../
	git add .
	# Commit changes.
	msg="rebuilding site `date`"
	if [ $# -eq 1 ]
	  then msg="$1"
	fi
	git commit -m "$msg"

	# Push source and build repos.
	git push origin main

	# Come Back up to the Project Root
	cd $BLOG_DIR
}
# main
cd $BLOG_DIR
case "$1" in
    common)
        post_common_article "$2" "$3"
        ;;
    drainage)
        post_drainage_article "$2" "$3"
        ;;
    deploy)
        build_hugo_and_push
        ;;
    *)
        echo "Usage: $0 {common|drainage|deploy}"
        echo "       $0 common dir blog_name "
        echo "       $0 drainage dir blog_name "
        echo "       $0 deploy "
        exit 1
esac

exit $?
