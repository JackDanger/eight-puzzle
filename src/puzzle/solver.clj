(ns puzzle.solver (:gen-class))

(def size 3); change to 4 to do a 15 puzzle

(defn abs [n]
  (if (< 0 n) n (- n)))

(defrecord State [puzzle path])

(defn puzzle [p]
  "
  Takes a vector/list of (size*size)digits and
  returns a map where the keys are the cartesian
  coordinates and the values are the
  corresponding cell contents.
  "
  (apply assoc
         (cons {}
           (interleave
             (for [y (range size)
                   x (range size)]
                [x y])
             p))))

(defn plist [s]
  "
  Takes a state and returns the (size*size) digits of the
  puzzle cell values in order.
  "
  (let [p (:puzzle s)]
    (for [y (range size)
          x (range size)] (p [x y]))))

(def solution (puzzle (range (* size size))))
(def solution-positions (into {} (map (fn [[k v]] [v k]) solution)))

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

(def pq-comparator (comparator (fn [a b] (< (a 1) (b 1)))))
(def frontier (java.util.PriorityQueue. 1000000 pq-comparator))

(defn branch [state dir]
  (let [puzzle (:puzzle state)
        blank-pos ((first (filter (fn [[pos v]] (zero? v)) puzzle)) 0)
        blankx (blank-pos 0)
        blanky (blank-pos 1)
        min 0
        max (dec size)
        [impossible swap]
          (case dir
            :left  [(= min (blank-pos 0)) [(dec blankx) blanky]]
            :right [(= max (blank-pos 0)) [(inc blankx) blanky]]
            :up    [(= min (blank-pos 1)) [blankx (dec blanky)]]
            :down  [(= max (blank-pos 1)) [blankx (inc blanky)]])]
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

(defn search [state visited]
  (let [bs (filter #(not (contains? visited (plist %))) (branches state))]
    ; add all new branches to the frontier
    ;(if (zero? (mod (.size frontier) 150)) (println (.size frontier) ((.peek frontier) 1)))
    (dorun (for [b bs] (.add frontier [b (f b)])))
    (if (not (zero? (.size frontier)))
      [((.remove frontier) 0)
       (conj visited (plist state))])))

(defn solve [start]
  (loop [state    start
         visited  #{}]
    (let [[state# visited#] (search state visited)]
      (if (= solution (:puzzle state#))
          (println state# "\nsolved in" (g state#) "steps")
          (if state#
            (recur state# visited#)
            (str "not found in " (count visited) "nodes"))))))

(def p8a  (puzzle [5 3 7 8 1 2 4 0 6]))
(def p15a (puzzle [5 4 7 8 14 13 12 11 1 2 3 0 10 15 9 6]))
(def s15 (->State p15a '()))

(defn solveable [n-steps]
  (loop [n n-steps
         s (->State solution '())]
    (if (zero? n) (->State (:puzzle s) '())
      (let [bs (branches s)
            which (int (Math/floor (* (rand) (count bs))))]
        (recur (dec n)
               (nth bs which))))))

(defn -main [& args]
  (dorun (for [n (range 10)] (time (println (solve (solveable (Integer/parseInt (first args)))))))))
