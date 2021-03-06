import Lake
open System Lake DSL

package ffi {
  srcDir := "lean"
  precompileModules := true
}

lean_lib FFI

@[defaultTarget] lean_exe test {
  root := `Main
}

def pkgDir := __dir__
def cSrcDir := pkgDir / "c"
def cBuildDir := pkgDir / _package.buildDir / "c"

def ffiOTarget : FileTarget :=
  let oFile := cBuildDir / "ffi.o"
  let srcTarget := inputFileTarget <| cSrcDir / "ffi.cpp"
  fileTargetWithDep oFile srcTarget fun srcFile => do
    compileO oFile srcFile #["-I", (← getLeanIncludeDir).toString, "-fPIC"] "c++"

extern_lib cLib :=
  let libFile := cBuildDir / nameToStaticLib "leanffi"
  staticLibTarget libFile #[ffiOTarget]
