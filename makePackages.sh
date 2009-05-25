#!/bin/bash
# Copyright (C) 2007 Paul Legato
#
# By Paul Legato (pjlegato at gmail dot com)
#
# == License
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA
#

VERSION=`pwd | awk -v FS=/ "{print \\$(NF) }"`

cd ..
ln -s $VERSION ib-ruby-$VERSION

tar --dereference --exclude .svn --exclude "*~" -jcf ../../packages/$VERSION/ib-ruby-$VERSION.tar.bz2 ib-ruby-$VERSION
rm  -f ../../packages/$VERSION/ib-ruby-$VERSION.zip
zip -9 -r ../../packages/$VERSION/ib-ruby-$VERSION.zip ib-ruby-$VERSION -x ".git" -x "*~"

rm ib-ruby-$VERSION
