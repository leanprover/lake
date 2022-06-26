/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Gabriel Ebner, Sebastian Ullrich, Mac Malone
-/
import Lake.Build.Monad

namespace Lake
open System

def createParentDirs (path : FilePath) : IO PUnit := do
  if let some dir := path.parent then IO.FS.createDirAll dir

def proc (args : IO.Process.SpawnArgs) : BuildM PUnit := do
  let envStr := String.join <| args.env.toList.filterMap fun (k, v) =>
    if k == "PATH" then none else some s!"{k}={v.getD ""} " -- PATH too big
  let cmdStr := " ".intercalate (args.cmd :: args.args.toList)
  logInfo <| "> " ++ envStr ++
    match args.cwd with
    | some cwd => s!"{cmdStr}    # in directory {cwd}"
    | none     => cmdStr
  let out ← IO.Process.output args
  let logOutputWith (log : String → BuildM PUnit) := do
    unless out.stdout.isEmpty do
      log s!"stdout:\n{out.stdout}"
    unless out.stderr.isEmpty do
      log s!"stderr:\n{out.stderr}"
  if out.exitCode = 0 then
    logOutputWith logInfo
  else
    logOutputWith logError
    logError s!"external command {args.cmd} exited with status {out.exitCode}"
    failure

def getSearchPath (envVar : String) : IO SearchPath := do
  match (← IO.getEnv envVar) with
  | some path => pure <| SearchPath.parse path
  | none => pure []

def compileLeanModule (leanFile : FilePath)
(oleanFile? ileanFile? cFile? : Option FilePath)
(oleanPath : SearchPath := []) (rootDir : FilePath := ".")
(dynlibs : Array FilePath := #[]) (dynlibPath : SearchPath := {})
(leanArgs : Array String := #[]) (lean : FilePath := "lean")
: BuildM PUnit := do
  let mut args := leanArgs ++
    #[leanFile.toString, "-R", rootDir.toString]
  if let some oleanFile := oleanFile? then
    createParentDirs oleanFile
    args := args ++ #["-o", oleanFile.toString]
  if let some ileanFile := ileanFile? then
    createParentDirs ileanFile
    args := args ++ #["-i", ileanFile.toString]
  if let some cFile := cFile? then
    createParentDirs cFile
    args := args ++ #["-c", cFile.toString]
  for dynlib in dynlibs do
    args := args.push s!"--load-dynlib={dynlib}"
  proc {
    args
    cmd := lean.toString
    env := #[
      ("LEAN_PATH", oleanPath.toString),
      ("PATH", (← getSearchPath "PATH") ++ dynlibPath |>.toString), -- Windows
      ("LD_LIBRARY_PATH", (← getSearchPath "LD_LIBRARY_PATH") ++ dynlibPath |>.toString), -- Unix
      ("DYLD_LIBRARY_PATH", (← getSearchPath "DYLD_LIBRARY_PATH") ++ dynlibPath |>.toString) -- MacOS
    ]
  }

def compileO (oFile srcFile : FilePath)
(moreArgs : Array String := #[]) (compiler : FilePath := "cc") : BuildM PUnit := do
  createParentDirs oFile
  proc {
    cmd := compiler.toString
    args := #["-c", "-o", oFile.toString, srcFile.toString] ++ moreArgs
  }

def compileStaticLib (libFile : FilePath)
(oFiles : Array FilePath) (ar : FilePath := "ar") : BuildM PUnit := do
  createParentDirs libFile
  proc {
    cmd := ar.toString
    args := #["rcs", libFile.toString] ++ oFiles.map toString
  }

def compileSharedLib (libFile : FilePath)
(linkArgs : Array String) (linker : FilePath := "cc") : BuildM PUnit := do
  createParentDirs libFile
  proc {
    cmd := linker.toString
    args := #["-shared", "-o", libFile.toString] ++ linkArgs
  }

def compileExe (binFile : FilePath) (linkFiles : Array FilePath)
(linkArgs : Array String := #[]) (linker : FilePath := "cc") : BuildM PUnit := do
  createParentDirs binFile
  proc {
    cmd := linker.toString
    args := #["-o", binFile.toString] ++ linkFiles.map toString ++ linkArgs
  }
