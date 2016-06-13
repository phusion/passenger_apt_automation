# Conceptual introduction to Debian packaging

The preferred method of installing software on Debian and Ubuntu is via Debian packages -- .deb files. This article provides a conceptual introduction into Debian packaging and describes the workflow, important tools and important parts of the ecosystem.

Most existing Debian packaging tutorials are targeted at third party packagers: that is, people who are interested in packaging software that they themselves did not write. However, this point of view may cause confusion for readers who are developers that want to package their own software. Many Debian packaging tutorials also assume that the software to be packaged uses autoconf, and/or reference obscure ecosystem parts without further explanation of what they are and how they fit in the overall picture.

This article aims to explain Debian packaging from the point of view of a developer who wants to package his own software, and does not assume any prior knowledge about the Debian packaging ecosystem. It is a conceptual introduction only, for the purpose of understanding the overall picture; it is not a tutorial on how to build a Debian packages. A tutorial may be published separately in the future.

**Table of contents**

 * [Anatomy of Debian packages](#anatomy-of-debian-packages)
 * [Building process](#building-process)
   - [Compilation is an integral part of package building](#compilation-is-an-integral-part-of-package-building)
 * [The `debian` directory](#the-debian-directory)
 * [Package building tools](#package-building-tools)
   - [dpkg-buildpackage and debuild: basic package building](#dpkg-buildpackage-and-debuild-basic-package-building)
   - [pbuilder: ensuring that the packaging specification is correct](#pbuilder-ensuring-that-the-packaging-specification-is-correct)
   - [pbuilder-dist: building packages for multiple distributions](#pbuilder-dist-building-packages-for-multiple-distributions)
 * [Binary vs source packages](#binary-vs-source-packages)
 * [APT repository](#apt-repository)
 * [Concluding summary](#concluding-summary)
 * [See also](#see-also)

## Anatomy of Debian packages

So you are a Debian/Ubuntu user. You search for a package with `apt-cache search`. You install a package with `apt-get install`. You already intuitively know these:

 * Packages contain basic metadata such as names and descriptions.
 * Packages may have dependencies.
 * Packages contain files.

Indeed. A Debian package -- a .deb file -- is sort of like a tar.gz or zip file containing **metadata** and **files**. It's not actually a tar.gz or zip: the format is [ar](https://en.wikipedia.org/wiki/Ar_(Unix)) but that's not important.

## Building process

Building a Debian package involves:

 1. Writing a specification of the packaging.
 2. Putting the specification in the same directory as the software's source code.
 3. Running a Debian package building. This turns that specification, plus the software's source code, into one or more package files.

### Compilation is an integral part of package building

There is one important caveat you should understand: _the packaging tool, not you, controls the compilation_.

If you are a developer who wants to publish a Debian package, then you may intuitively think that the Debian packaging tool expects a specification, plus a list of binaries and instructions on where those binaries need to be placed on the filesystem. If you have ever published Windows desktop software, OS X desktop software or Java software, then this is how it usually works. The Debian packaging tool *can* work this way, but almost nobody does it this way. And indeed, the tooling doesn't make it easy for you to do it this way.

Instead, the Debian packaging tools expect you to specify how your software is compiled, and how the compiled binaries should be placed on the filesystem. When you run the Debian packaging tools, they perform the compilation for you as part of the package building process.

The reason why the Debian packaging tools work like this have to do with the fact that they evolved from an open source setting where packagers are not the original developers. Third-party packagers wait for the developer to release a source tarball. Then s/he writes a specification that describes how the software is compiled. This is good for _repeatability_ and _sharing_. Instead of depending on the packager to run ad-hoc compilation commands, the compilation instructions are clearly specified so that other people can reproduce the work.

## The `debian` directory

The specification of the packaging is a collection of metadata such as descriptions and dependency information. The specification also contains compilation instructions.

The specification is not a single file. Instead, it is a directory containing multiple files, each with its own role. This directory is typically called `debian` and placed in the top-level source code directory of the software source tree you want to package. Inside this directory are at least two files:

 * control -- metadata such as descriptions and dependency information.
 * rules -- a makefile describing the compilation steps.

This package is supposed to contain everything related to packaging the software. That is, everything related to adapting the software for integration in Debian/Ubuntu. So the directory may contain additional files such as:

 * Man pages
 * Init scripts
 * Pre- and post-install scripts.
 * Patches.

## Package building tools

Debian provides a number of different tools for building Debian packages. Confusingly enough, they provide different yet partially overlapping functionality. The reason is historical: it started with a simple tool, and as requirements grew they added more tools instead of extending the old ones.

The tools that we think are most important are as follows, arranged from low-level to high-level:

 * dpkg-buildpackage and debuild
 * pbuilder
 * pbuilder-dist

### dpkg-buildpackage and debuild: basic package building

The dpkg-buildpackage tool is the most basic package building tool. It expects as input a directory containing:

 * the software's source code.
 * a `debian` subdirectory.

dpkg-buildpackage compiles the software using the `debian/rules` makefile and generates a package with the metadata specified in `debian/control`.

debuild builds on top of dpkg-buildpackage and provides a few more additional features. It is not entirely clear to me how debuild is different.

### pbuilder: ensuring that the packaging specification is correct

Pbuilder is a tool for building packages in an isolated environment so that you can more easily test a package's correctness.

Dpkg-buildpackage and debuild operate directly on the current operating system environment. This is fairly straightforward, but it has a drawback: it depends implicitly on your system's state. What does this mean?

Most software has dependencies. Various dependencies need to be installed before a piece of software can be compiled. Since Debian packages are supposed to be repeatable (other people should be able to take your `debian` directory and generate a package too), Debian allows you to specify *build dependencies* in the `debian/control` file.

How do you know whether your list of build dependencies is correct and complete? What if you have a build dependency installed, but forgot to list it in the control file? dpkg-buildpackage cannot help you there.

The pbuilder tool was invented to solve this problem. Pbuilder creates a clean, isolated Debian/Ubuntu system inside a chroot environment, installs all your build dependencies in there, then runs debuild in there. If you forgot to list a build dependency then you will encounter an error.

### pbuilder-dist: building packages for multiple distributions

A drawback of dpkg-buildpackage, debuild and pbuilder is that they can only build packages for the Debian/Ubuntu version that you are currently running. What if you need to publish packages for multiple distribution versions?

The pbuilder-dist tool addresses this problem. Pbuilder-dist builds on top of pbuilder and allows you to choose which Debian/Ubuntu version to put in the chroot. This way you can build packages for multiple distribution versions without having to install each distribution version manually.

## Binary vs source packages

To be precise, a .deb file is a **binary package**: it contains the final compiled binaries. But there is also this thing called **source packages**. Every binary package has a corresponding source package. Confusingly, a source package is not a single file: it is actually three files, and the collection of these three files is called a source package.

What is a source package good for? Well, a source package contains everything you need to generate the corresponding binary package; it contains all input passed to the package building tool:

 * the source code of the software that's being packaged. This is called the "orig tarball".
 * a `debian` directory in archive (either tar.gz or tar.xz).
 * a signature file (.dsc) containing signatures of the orig tarball and the `debian` directory archive.

## APT repository

Users rarely interact with .deb files directly. Instead, they tend to interact with APT repositories. An APT repository is a directory containing .deb files and various metadata files such as index files and signature files.

You can either create an APT repository yourself from local Debian packages on the filesystem. One of the easiest and best documented tools for creating APT repositories is [Reprepro](https://mirrorer.alioth.debian.org/). But Reprepro has a few drawbacks, such as not having support for hosting multiple versions of packages. Unfortunately other tools have their own drawbacks: the tool that Debian and Ubuntu use for maintaining their APT repositories are more full-featured, but have awful documentation.

Alternatively, you can upload your Debian packages to a hosted APT repository services such as:

 * Ubuntu Personal Package Archive (PPA), also known as Launchpad
 * [PackageCloud](https://packagecloud.io/)

The service then takes care of maintaining the APT repository and for hosting the files for you. Ubuntu PPA is, as the name implies, for hosting Ubuntu APT repositories only. Its interface is also very weird, making it potentially harder to use than Repropro. PackageCloud is a much more sane service and provides friendly documentation, APIs and tools, but they are a paid service while Ubuntu PPA is a free community service.

Phusion hosts their packages on PackageCloud.

## Concluding summary

A Debian binary package is a .deb file containing files, as well as metadata such as dependency information. A binary package has a corresponding source package, which is a collection of files from which the binary package can be recreated.

Building a Debian package involves:

1. Writing a specification of the packaging.
2. Putting the specification in the same directory as the software's source code.
3. Running a Debian package building tool. This turns that specification, plus the software's source code, into one or more package files.

Compilation is an integral part of package building. You aren't supposed to supply binaries to the package building tool. Instead, you are supposed to write a specification of how your software is compiled, and then the Debian package building tool will compile your software for you, and then package the resulting binaries.

The packaging specification is a directory named `debian`. In addition to containing metadata and instructions on compiling the software, it can also contain additional files needed for packaging the software, such as man pages, init scripts and more.

There are four important tools for building packages. On the lowest level are dpkg-buildpackage and debuild: they provide basic package building services. Pbuilder and pbuilder-dist are other tools built on top of the previous tools: they provide isolated chroot environments in which to run dpkg-buildpackage and debuild so that you test your package specification for correctness, and so that you can easily build packages for multiple distribution versions.

And finally, an APT repository is a directory containing Debian packages as well as metadata files such as index files and signature files. Users usually interact with, instead APT repositories instead of directly with raw .deb files. There are various tools for creating APT repositories, such as [Reprepro](https://mirrorer.alioth.debian.org/). Hosted services such as Ubuntu PPA/Launchpad and [PackageCloud](https://packagecloud.io/) also exist.

## See also

 * [Debian Packaging Intro](https://wiki.debian.org/Packaging/Intro)
 * [Debian New Maintainers Guide](https://www.debian.org/doc/manuals/maint-guide/index.en.html)
 * [Debian Policy Manual](https://www.debian.org/doc/debian-policy/index.html)
