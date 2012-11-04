(ns puzzle.solver
  (:gen-class)
  (:require [lanterna.screen :as s]))

(def scr (s/get-screen :swing))

(defn put [x y & s#]
  (s/put-string scr x y (apply str s#)))

(defn redraw []
  (s/redraw scr))

(defn cell [puzzle n]
  (let [v (nth puzzle (int n))]
    (if (= 0 v) " " v)))

(defn row [& parts]
  (apply str parts))

(defn display [puzzle]
  (dorun
    (for [n (range 7)]
      (if (even? n)
        ; gap row
        (put 2 (+ 5 n) " --- --- --- ")
        ; content row
        (put 2 (+ 5 n)
             "| "
             (cell puzzle (+ 0 (* 3 (Math/floor (/ n 2)))))
             " | "
             (cell puzzle (+ 1 (* 3 (Math/floor (/ n 2)))))
             " | "
             (cell puzzle (+ 2 (* 3 (Math/floor (/ n 2)))))
             " |"))))
  (redraw))

(def p1 [8 3 7 9 1 2 4 0 6])

(defn -main [& args]
  (println "in main")
  (s/in-screen scr
    (display p1)
    (s/get-key-blocking scr)))
