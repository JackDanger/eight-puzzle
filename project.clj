(defproject eight-puzzle "1.0.0-SNAPSHOT"
  :description "FIXME: write description"
  :dependencies [
                 [org.clojure/clojure "1.3.0"]
                 [speclj "2.1.2"]
                 ]
  :plugins [[speclj "2.1.2"]]
  :test-paths ["spec/"]
  :main eight-puzzle.solver)
