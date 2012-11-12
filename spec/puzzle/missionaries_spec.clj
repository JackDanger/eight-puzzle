(ns puzzle.missionaries-spec
  (:require [puzzle.missionaries :refer :all]
            [speclj.core :refer :all]))

(defmacro desc [subject & forms]
  (list 'let ['subject subject]
    (apply list 'describe (str subject) forms)))
(defmacro where [name object & forms]
  (list 'let ['object object 'where-name (str "where " name)]
    forms))
(defmacro its [expected]
  (list 'it (list 'str 'where-name " is " expected) (list 'should= expected (list 'subject 'object))))

(desc valid?
  (where "the left bank has too many cannibals"
    (->State {:left [:m :c :c] :boat [:c :m] :right [:m]} '())
    its false)
  (where "the right bank has too many cannibals"
    (->State {:left [:m] :boat [:c :m] :right [:c :c :m]} '())
    its false)
  (where "no one place has an abundance of cannibals"
    (->State {:left [:m :c] :boat [:c :m] :right [:c :m :m]} '())
    its true))

(desc solve
  (where "they all start on the left"
    start
    its solution))
