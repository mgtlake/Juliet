# Juliet - Julia Interactive Educational Tutor

Windows build: [![Build status](https://ci.appveyor.com/api/projects/status/qrnaiu4tix9g0ot8?svg=true)](https://ci.appveyor.com/project/matthew-lake/juliet)

Unix build: [![Build Status](https://travis-ci.org/matthew-lake/Juliet.svg?branch=master)](https://travis-ci.org/matthew-lake/Juliet)

Kind-of-dodgy coverage stats: [![Coverage Status](https://coveralls.io/repos/github/matthew-lake/Juliet/badge.svg?branch=master)](https://coveralls.io/github/matthew-lake/Juliet?branch=master)


Juliet is a interactive tutor for Julia that provides a simple yet powerful tutorial framework.
It is currently a Google Summer of Code project for the Julia Language.

Though development is at an early stage, please feel free to give feedback or advice. I am unable to test on all systems - if you have a problem, open an issue with your system details and steps to reproduce.

All code is released under the MIT license.


## Julia 0.5 Compatibility Issues

Currently not of Juliet's dependencies work in Julia 0.5. I have reached out to their maintainers, but cannot guarantee speedy updates. Should they remain incompatible for too long after 0.5's launch, I will endevor to find or create replacements.

## Notes on Tests and Coverage

The Julia 0.5 tests are currently failing due to the issues described above, but the tests pass on 0.4 on Windows, Linux and Mac.
Coverage is currently underreported because the major tests model real-user interaction by running a new process and piping input to it, then observing STDOUT. Unfortunately, Coveralls does not keep track of this.
