(defproject eight-puzzle "1.0.0-SNAPSHOT"
  :description "FIXME: write description"
  :dependencies [
                 [org.clojure/clojure "1.4.0"]
                 [speclj "2.1.2"]
                 [clojure-lanterna "0.9.2"]
                 [org.clojure/data.priority-map "0.0.2"]
                 ]
  :plugins [[speclj "2.1.2"]]
  :test-paths ["spec/"]
  :gen-class true
  :aot [puzzle.eight-puzzle]
  :main puzzle.eight-puzzle)
