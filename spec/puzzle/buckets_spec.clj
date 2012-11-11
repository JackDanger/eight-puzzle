(ns puzzle.buckets-spec
  (:require [puzzle.buckets :refer :all]
            [speclj.core :refer :all]))

(describe "lcds-for"
  (it "returns pairs for simple input"
    (should= {1 [3 5]
              2 [5 3]}
             (lcds-in 3 5)))
  (it "returns lowest possible pairs for complex input"
    (should= {1 [3 5]
              2 [5 3]
              6 [7 8]
              3 [5 7]}
             (lcds-in 3 5 8 7))))

;(describe "solve"
;  (it "solves the simple case"
;    (should= '([3 5] [3 5] [3 :scale])
;             (solve 1 3 5))))
