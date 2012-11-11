(ns puzzle.buckets (:gen-class))

(defn abs [n]
  (if (< 0 n) n (- n)))

(defn mark [& args]
  "
  'bout time I wrote this.
  "
  (apply println args)
  (last args))
(defn choose-best [m [amount pair]]
  "
  Given a map and a new way to calculate an amount
  return a map that chooses the cheapest way to
  calculate that amount.
  "
    (let [total (reduce + pair)
          current (get m amount pair)
          current-total (reduce + current)]
      (if (and total (< total current-total))
          (conj m {amount pair})
          (conj m {amount current}))))

(defn lcds-in [& sizes]
  "
  Given a set of numbers n in sizes we calculate
  which minimum discrete amounts can be found by
  subtracting the numbers from each other.
  Returns pairs of pairs where the first set in
  each pair is the sizes involved in the calculation
  and the second element is the difference value
  "
  (let [sizes (distinct sizes)
        all (set sizes)]
    (reduce choose-best {}
           (for [s1 sizes
                 s2 (disj all s1)]
               ; What happens when `size` bucket gets poured into `other-size`
               ; e.g. 5 into 3 -> 2 (mod)
               ;      3 into 5 -> 1 (remainder)
              [(if (> s1 s2)
                (mod s1 s2)
                (- (* s1 (int (Math/ceil (/ s2 s1)))) s2))
               [s1 s2]]))))

(defrecord Operation [])
(defrecord State [measured bucket-with-water rem-sizes operations])

(defn solve [goal & bucket-sizes]
  "
  Given a goal amount (e.g. 1 litre)
  and the sizes of available buckets we look for
  some combination of filling the buckets and pouring
  them into each other or onto the ground that can
  yield the desired goal amount.
  "
  (loop [lcds (lcds-in bucket-sizes)
         operations '()]
    (if (lcds goal)
        (concat operations []) ;(operate needed (lcds needed)))
        (let [step (reduce min (keys (lcds)))]
          (recur (- goal step)
                 step)))))

(defn -main [& args]
  (apply solve args))
