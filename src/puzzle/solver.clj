(ns puzzle.solver
  (:gen-class)
  (:require [clojure.data.priority-map]))
  ;(:require [lanterna.screen :as s]))

;(def scr (s/get-screen :swing))
;(defn put [x y & s#]
  ;(s/put-string scr x y (apply str s#)))
;(defn redraw []
  ;(s/redraw scr))
;(defn display [puzzle]
;  (dorun
;    (for [n (range 7)]
;      (if (even? n)
;        ; gap row
;        (put 2 (+ 5 n) " --- --- --- ")
;        ; content row
;        (put 2 (+ 5 n)
;             "| "
;             (cell puzzle (+ 0 (* 3 (Math/floor (/ n 2)))))
;             " | "
;             (cell puzzle (+ 1 (* 3 (Math/floor (/ n 2)))))
;             " | "
;             (cell puzzle (+ 2 (* 3 (Math/floor (/ n 2)))))
;             " |"))))
;  (redraw))
;(defn cell [puzzle n]
;  (let [v (nth puzzle (int n))]
;    (if (= 0 v) " " v)))
;(defn row [& parts]
;  (apply str parts))

(defn abs [n]
  (if (< 0 n) n (- n)))

(defrecord State [puzzle path])

(defn puzzle [p]
  "
  Takes a vector/list of 9 digits and
  returns a map where the keys are the cartesian
  coordinates and the values are the
  corresponding cell contents.
  "
  (apply assoc
         (cons {}
           (interleave
             (for [y (range 3)
                   x (range 3)]
                [x y])
             p))))

(defn plist [s]
  "
  Takes a state and returns the 9 digits of the
  puzzle cell values in order.
  "
  (let [p (:puzzle s)]
    (for [y (range 3)
          x (range 3)] (p [x y]))))

(def solution (puzzle (range 9)))
(def solution-positions (into {} (map (fn [[k v]] [v k]) solution)))

(def visited (java.util.PriorityQueue. 1000000 (comparator (fn[a b](< (a 1)(b 1))))))

(defn manhattan-distance [[x1 y1] [x2 y2]]
  (+ (abs (- x1 x2))
     (abs (- y1 y2))))

(defn g [state]
  "The cost of taking this path up to the current point"
  (count (:path state)))

(defn h [state]
  "The cost of solving this puzzle, under ideal conditions"
  (reduce +
     (for [[c v] (:puzzle state)]
       (manhattan-distance c (get solution-positions v)))))

(defn f [state]
  "
  The cost of getting into this state plus the cost
  of reaching our goal from this state (optimistically).
  This implements the A* search.
  "
  (+ (g state) (h state)))

(defn branch [state dir]
  (let [puzzle (:puzzle state)
        blank-pos ((first (filter (fn [[pos v]] (zero? v)) puzzle)) 0)
        blankx (blank-pos 0)
        blanky (blank-pos 1)
        [impossible swap]
          (case dir
            :left  [(= 0 (blank-pos 0)) [(dec blankx) blanky]]
            :right [(= 2 (blank-pos 0)) [(inc blankx) blanky]]
            :up    [(= 0 (blank-pos 1)) [blankx (dec blanky)]]
            :down  [(= 2 (blank-pos 1)) [blankx (inc blanky)]])]
    (if impossible
      nil
      (->State (assoc puzzle
                      blank-pos (puzzle swap)
                      swap 0)
               (conj (:path state) dir)))))

(defn branches [state]
  "Retrieve all adjacent states from the current one"
  (filter (comp not nil?)
          (for [dir [:up :down :left :right]]
               (branch state dir))))

(defn search [state frontier]
  (let [next-frontier (reduce conj frontier (map (fn [b] [b (f b)]) (branches state)))
        next-state ((first next-frontier) 0)]
    [next-state
     (pop next-frontier)
     (conj visited (plist state))]))

(defn solve [start]
  (loop [state    start
         frontier (clojure.data.priority-map/priority-map)
         visited  #{}]
    (let [[state# frontier#] (search state frontier)]
      (if (= 0 (mod (count frontier) 100))
        (println "frontier:" (count frontier)
                 "visited:" (.size visited)
                 "path length: " (count (:path state))
                 "head cost: " (f state)))
      (if (= solution (:puzzle state#))
          state#
          (if state#
            (recur state# frontier# visited#)
            "not found")))))

(def p1 (puzzle [8 3 7 5 1 2 4 0 6]))
(def s1 (->State p1 '()))

(defn -main [& args]
  (println (solve s1)))
  ;(s/in-screen scr
    ;(display p1)
    ;(s/get-key-blocking scr)))
