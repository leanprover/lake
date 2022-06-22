/-
Copyright (c) 2022 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
import Lake.Build.Trace
import Lake.Config.Package
import Lake.Util.Name

namespace Lake
open System Lean

/-- A buildable Lean module of a `Package`. -/
structure Module where
  pkg : Package
  name : WfName
  deriving Inhabited

/-- Locate the named module in the package (if it is local to it). -/
def Package.findModule? (mod : Name) (self : Package) : Option Module :=
  let mod := WfName.ofName mod
  if self.isBuildableModule mod then some ⟨self, mod⟩ else none

namespace Module

def leanFile (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.srcDir self.name "lean"

def oleanFile (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.oleanDir self.name "olean"

def ileanFile (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.oleanDir self.name "ilean"

def traceFile (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.oleanDir self.name "trace"

def cFile (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.irDir self.name "c"

def cTraceFile (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.irDir self.name "c.trace"

def oFile (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.irDir self.name "o"

def dynlib (self : Module) : FilePath :=
  Lean.modToFilePath self.pkg.oleanDir self.name sharedLibExt

@[inline] def leanArgs (self : Module) : Array String :=
  self.pkg.moreLeanArgs

@[inline] def leancArgs (self : Module) : Array String :=
  self.pkg.moreLeancArgs

@[inline] def linkArgs (self : Module) : Array String :=
  -- TODO: derive link arguments from library, not package
  self.pkg.config.moreLinkArgs

@[inline] def shouldPrecompile (self : Module) : Bool :=
  self.pkg.precompileModules

-- ## Trace Helpers

protected def getMTime (self : Module) : IO MTime := do
  return mixTrace (← getMTime self.oleanFile) (← getMTime self.ileanFile)

instance : GetMTime Module := ⟨Module.getMTime⟩

protected def computeHash (self : Module) : IO Hash := do
  return mixTrace (← computeHash self.oleanFile) (← computeHash self.ileanFile)

instance : ComputeHash Module IO := ⟨Module.computeHash⟩

protected def checkExists (self : Module) : BaseIO Bool := do
  return (← checkExists self.oleanFile) && (← checkExists self.ileanFile)

instance : CheckExists Module := ⟨Module.checkExists⟩
