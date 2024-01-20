#!/bin/bash

BLOG_DIR=/home/donge/WorkSpace/uniondong.github.io
COMMON_POST_TEMPLATE="common_post"
DRAINAGE_POST_TEMPLATE="drainage"

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
}

# main
case "$1" in
    common)
        post_common_article "$2" "$3"
        ;;
    funcs)
        trace_functions "$2"
        ;;
    funcs_stack)
        trace_functions_with_stack "$2"
        ;;
    command)
        trace_command "$2" "$3"       # don't clear
        ;;
    clear)
        trace_clear
        ;;
    *)
        echo "Usage: $0 {common|drainage|deploy}"
        echo "       $0 common dir blog_name "
        echo "       $0 drainage dir blog_name "
        echo "       $0 deploy "
        exit 1
esac

exit $?
