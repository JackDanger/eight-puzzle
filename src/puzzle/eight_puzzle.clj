(ns puzzle.eight-puzzle (:gen-class))

(def size 3); change to 4 to do a 15 puzzle

(defn abs [n]
  (if (< 0 n) n (- n)))

(defrecord State [puzzle path])

(def solution (vec (range (* size size))))

(defn coords [idx]
  "Return the x and y coordinates in a puzzle for the given index"
  [(mod idx size)
   (int (/ idx size))])

(defn manhattan-distance [[x1 y1] [x2 y2]]
  (+ (abs (- x1 x2))
     (abs (- y1 y2))))

(defn g [state]
  "The cost of taking this path up to the current point"
  (count (:path state)))

(defn h [state]
  "The cost of solving this puzzle, under ideal conditions"
  (let [puzzle (:puzzle state)]
    (reduce +
      (for [idx (range (* size size))]
        (manhattan-distance (coords idx)
                            (coords (nth puzzle idx)))))))

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
  (let [puzzle (vec (:puzzle state))
        ; The 0 position == the number of elements that appear before 0
        blank-pos (count (take-while (comp not zero?) puzzle))
        blankx (first (coords blank-pos))
        blanky (last  (coords blank-pos))
        min 0
        max (dec size)
        [impossible swap]
          (case dir
            :left  [(= min blankx) (dec blank-pos)]
            :right [(= max blankx) (inc blank-pos)]
            :up    [(= min blanky) (- blank-pos size)]
            :down  [(= max blanky) (+ blank-pos size)])]
    (if impossible
      nil
      (->State (-> puzzle
                     (assoc blank-pos (puzzle swap))
                     (assoc swap 0))
               (conj (:path state) dir)))))

(defn branches [state]
  "Retrieve all adjacent states from the current one"
  (filter (comp not nil?)
          (for [dir [:up :down :left :right]]
               (branch state dir))))

(defn search [state visited]
  (let [bs (filter #(not (contains? visited (:puzzle %))) (branches state))]
    ;(if
    ;  (zero? (mod (.size frontier) 150))
    ;  (println (.size frontier) (if-let [f (.peek frontier)] (f 1))))
    ; add all new branches to the frontier
    (dorun (for [b bs] (.add frontier [b (f b)])))
    (if (not (zero? (.size frontier)))
      [((.remove frontier) 0)
       (apply conj visited (:puzzle state) (map :puzzle bs))])))

(defn solve [start]
  (loop [state    start
         visited  #{}]
    (if (= solution (:puzzle state))
      (println (:puzzle start) "\nsolved in" (g state) "steps:" (:path state))
      (let [[state# visited#] (search state visited)]
          (if state#
            (recur state# visited#)
            (str "not found in " (count visited) "nodes"))))))

(def p8a  [5 3 7 8 1 2 4 0 6])
(def p15a [5 4 7 8 14 13 12 11 1 2 3 0 10 15 9 6])
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
  (dorun (for [n (range 10)] (time (solve (solveable (Integer/parseInt (first args))))))))
