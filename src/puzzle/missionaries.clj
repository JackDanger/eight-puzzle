(ns puzzle.missionaries (:gen-class))

(def start    {:left [:m :m :m :c :c :c] :boat [] :right []})
(def solution {:left [] :boat [] :right [:m :m :m :c :c :c]})

(defrecord State [positions operations])

(defmacro -d [& forms]
  (list 'let ['v (apply list forms)] (list 'println (list 'quote forms) " -> " 'v) 'v))

(defn valid? [s]
  (not-any? #(> (count (filter (fn [a] (= :c a)) %))
                (count (filter (fn [a] (= :m a)) %)))
            (for [[_ pos] (:positions s)] pos)))

(defn branches [state visited]
  (let [bs [(load-boat :left state)
            (load-boat :right state)
            (unload-boat :right state)
            (unload-boat left state)]]))
(defn solve [begin]
  (loop [state (->State begin '())
         frontier '()
         visited #{}]
    (println (count frontier))
    (if (= solution (:positions state))
      state
      (let [[bs visited#] (branches state visited)
            frontier# (reduce conj frontier bs)]
        (recur (first frontier#) (rest frontier#) visited#)))))
