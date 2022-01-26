import Lake
open System Lake DSL

package bar where
  precompileModules := true
  defaultFacet := PackageFacet.oleans
  dependencies := #[
    { name := `foo, src := Source.path (FilePath.mk ".." /  "foo") }
  ]
