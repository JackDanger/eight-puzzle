(ns puzzle.buckets (:gen-class))

(defn abs [n]
  (if (< 0 n) n (- n)))

(defn lcds-in [sizes]
  "
  Given a set of numbers n in sizes we calculate
  which minimum discrete amounts can be found by
  subtracting the numbers from each other.
  Returns pairs of pairs where the first set in
  each pair is the sizes involved in the calculation
  and the second element is the difference value
  "
  (for [sizes (distinct sizes)
        s1 sizes
        s2 (disj (set sizes) s1)]
      ; What happens when `size` bucket gets poured into `other-size`
      ; e.g. 5 into 3 -> 2 (mod)
      ;      3 into 5 -> 1 (remainder)
      [[s1 s2]
       (if (> s1 s2)
         (mod s1 s2)
         (- (* s2 (int (Math/ceil (/ s2 s1)))) s2))]))

(defn solve [goal & bucket-sizes]
  "
  Given a goal amount (e.g. 1 litre)
  and the sizes of available buckets we look for
  some combination of filling the buckets and pouring
  them into each other or onto the ground that can
  yield the desired goal amount.
  "
  (let [lcds (lcds-in bucket-sizes)] ()))

(defn -main [& args]
  (apply solve args))
