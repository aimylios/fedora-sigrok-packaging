#!/bin/bash

set -e
set -x

clone_repository()
{
    REPOSITORY=$1
    if [ -d $REPOSITORY ]; then
        echo "Updating $REPOSITORY repository..."
        cd $REPOSITORY
        git fetch origin
        git reset --hard origin/master
        git checkout HEAD
        cd ..
    else
        echo "Cloning $REPOSITORY repository..."
        git clone git://sigrok.org/$REPOSITORY
        cd $REPOSITORY
        git checkout HEAD
        cd ..
    fi
}

get_current_revision()
{
    local REPOSITORY=$1
    cd $REPOSITORY
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
    cd ..
}

export_tarball()
{
    local REPOSITORY=$1
    local VERSION=$2
    local NAME=${REPOSITORY,,}
    if [ ! -f ./rpmbuild/SOURCES/$NAME-$VERSION.tar.gz ]; then
        rm -rf ./rpmbuild/SOURCES/$NAME-r*.tar.gz
        cd $REPOSITORY
        echo "Creating $NAME-$VERSION.tar.gz ..."
        git archive --format=tar.gz --prefix=$NAME-$VERSION/ HEAD > ../rpmbuild/SOURCES/$NAME-$VERSION.tar.gz
        cd ..
    fi
}

build_package()
{
    local REPOSITORY=$1
    local VERSION=$2
    local NAME=${REPOSITORY,,}
    FEDVER=$(rpm -E "%{dist}")
    sed s/REVISION_NUMBER/$VERSION/g $NAME.spec.template > ./rpmbuild/SPECS/$NAME.spec
    if [ ! -f ./rpmbuild/SRPMS/$NAME-$VERSION-nightly$FEDVER.src.rpm ]; then
        rm -rf ./rpmbuild/SRPMS/$NAME-r*.src.rpm
        rpmbuild --define "_topdir rpmbuild" --undefine "_disable_source_fetch" -bs "rpmbuild/SPECS/$NAME.spec"
        SRPM=$(find rpmbuild/SRPMS -name "$NAME-r*.src.rpm")
        copr-cli build aimylios/sigrok-weekly "${SRPM}"
    fi
}

[ -d rpmbuild ] || mkdir rpmbuild
cd rpmbuild
[ -d SPECS ] || mkdir SPECS
[ -d SOURCES ] || mkdir SOURCES
[ -d SRPMS ] || mkdir SRPMS
cd ..

clone_repository "libserialport"
LIBSP_REV=$(get_current_revision libserialport)
export_tarball   "libserialport" $LIBSP_REV
build_package    "libserialport" $LIBSP_REV

clone_repository "libsigrok"
LIBSIGROK_REV=$(get_current_revision libsigrok)
export_tarball   "libsigrok" $LIBSIGROK_REV
build_package    "libsigrok" $LIBSIGROK_REV

clone_repository "libsigrokdecode"
LIBSIGROKDEC_REV=$(get_current_revision libsigrokdecode)
export_tarball   "libsigrokdecode" $LIBSIGROKDEC_REV
build_package    "libsigrokdecode" $LIBSIGROKDEC_REV

clone_repository "sigrok-cli"
SIGROKCLI_REV=$(get_current_revision sigrok-cli)
export_tarball   "sigrok-cli" $SIGROKCLI_REV
build_package    "sigrok-cli" $SIGROKCLI_REV

clone_repository "pulseview"
PULSEVIEW_REV=$(get_current_revision pulseview)
export_tarball   "pulseview" $PULSEVIEW_REV
build_package    "pulseview" $PULSEVIEW_REV

clone_repository "sigrok-firmware-fx2lafw"
FX2LAFW_REV=$(get_current_revision sigrok-firmware-fx2lafw)
export_tarball   "sigrok-firmware-fx2lafw" $FX2LAFW_REV
build_package    "sigrok-firmware-fx2lafw" $FX2LAFW_REV

exit 0
