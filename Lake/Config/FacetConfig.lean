/-
Copyright (c) 2022 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
import Lake.Build.Info
import Lake.Build.Store
import Lake.Build.Topological

namespace Lake

abbrev BuildStoreM := StateT BuildStore BuildM
abbrev BuildConfigM := CycleT BuildKey BuildStoreM

instance : MonadLift BuildM BuildConfigM := ⟨liftM⟩

/-- A facet's declarative configuration. -/
structure FacetConfig (DataFam : Name → Type) (ι : Type) (name : Name) : Type where
  /-- The facet's build function. -/
  build : ι → IndexT BuildConfigM (DataFam name)
  /-- Is this facet a buildable target? -/
  target? : Option ((info : BuildInfo) → BuildData info.key = DataFam name → OpaqueTarget.{0})

instance : Inhabited (FacetConfig DataFam ι name) := ⟨{
  build := fun _ => liftM (m := BuildM) failure
  target? := none
}⟩

protected def FacetConfig.name (_ : FacetConfig DataFam ι name) :=
  name

/-- A dependently typed configuration based on its registered name. -/
structure NamedConfigDecl (β : Name → Type u) where
  name : Name
  config : β name

--------------------------------------------------------------------------------

/-- A module facet's declarative configuration. -/
abbrev ModuleFacetConfig := FacetConfig ModuleData Module
hydrate_opaque_type OpaqueModuleFacetConfig ModuleFacetConfig name

/-- A module facet declaration from a configuration file. -/
abbrev ModuleFacetDecl := NamedConfigDecl ModuleFacetConfig

--------------------------------------------------------------------------------

/-- A package facet's declarative configuration. -/
abbrev PackageFacetConfig := FacetConfig PackageData Package
hydrate_opaque_type OpaquePackageFacetConfig PackageFacetConfig name

/-- A package facet declaration from a configuration file. -/
abbrev PackageFacetDecl := NamedConfigDecl PackageFacetConfig
