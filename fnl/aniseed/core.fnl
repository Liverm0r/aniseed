(module aniseed.core
  {require {view aniseed.view}})

(defn first [xs]
  (when xs
    (. xs 1)))

(defn last [xs]
  (when xs
    (. xs (length xs))))

(defn second [xs]
  (when xs
    (. xs 2)))

(defn string? [x]
  (= "string" (type x)))

(defn nil? [x]
  (= nil x))

(defn table? [x]
  (= "table" (type x)))

(defn count [xs]
  (if
    (table? xs) (table.maxn xs)
    (not xs) 0
    (length xs)))

(defn inc [n]
  "Increment n by 1."
  (+ n 1))

(defn dec [n]
  "Decrement n by 1."
  (- n 1))

(defn keys [t]
  "Get all keys of a table."
  (let [result []]
    (when t
      (each [k _ (pairs t)]
        (table.insert result k)))
    result))

(defn vals [t]
  "Get all values of a table."
  (let [result []]
    (when t
      (each [_ v (pairs t)]
        (table.insert result v)))
    result))

(defn kv-pairs [t]
  "Get all keys and values of a table zipped up in pairs."
  (let [result []]
    (when t
      (each [k v (pairs t)]
        (table.insert result [k v])))
    result))

(defn update [tbl k f]
  "Swap the value under key `k` in table `tbl` using function `f`."
  (tset tbl k (f (. tbl k)))
  tbl)

(defn run! [f xs]
  "Execute the function (for side effects) for every xs."
  (when xs
    (let [nxs (count xs)]
      (when (> nxs 0)
        (for [i 1 nxs]
          (f (. xs i)))))))

(defn filter [f xs]
  "Filter xs down to a new sequential table containing every value that (f x) returned true for."
  (let [result []]
    (run!
      (fn [x]
        (when (f x)
          (table.insert result x)))
      xs)
    result))

(defn map [f xs]
  "Map xs to a new sequential table by calling (f x) on each item."
  (let [result []]
    (run!
      (fn [x]
        (let [mapped (f x)]
          (table.insert
            result
            (if (= 0 (select "#" mapped))
              nil
              mapped))))
      xs)
    result))

(defn map-indexed [f xs]
  "Map xs to a new sequential table by calling (f [k v]) on each item. "
  (map f (kv-pairs xs)))

(defn identity [x]
  "Returns what you pass it."
  x)

(defn reduce [f init xs]
  "Reduce xs into a result by passing each subsequent value into the fn with
  the previous value as the first arg. Starting with init."
  (var result init)
  (run!
    (fn [x]
      (set result (f result x)))
    xs)
  result)

(defn some [f xs]
  "Return the first truthy result from (f x) or nil."
  (var result nil)
  (var n 1)
  (while (and (not result) (<= n (length xs)))
    (let [candidate (f (. xs n))]
      (when candidate
        (set result candidate))
      (set n (inc n))))
  result)

(defn concat [...]
  "Concatinats the sequential table arguments together."
  (let [result []]
    (run! (fn [xs]
            (run!
              (fn [x]
                (table.insert result x))
              xs))
      [...])
    result))

(defn println [...]
  (let [msg (->> [...]
                 (map-indexed
                   (fn [[i s]]
                     (if (= 1 i)
                       s
                       (.. " " s))))
                 (reduce
                   (fn [acc s]
                     (.. acc s))
                   ""))]
    (print msg)))

(defn slurp [path]
  "Read the file into a string."
  (match (io.open path "r")
    (nil msg) (println (.. "Could not open file: " msg))
    f (let [content (f:read "*all")]
        (f:close)
        content)))

(defn spit [path content]
  "Spit the string into the file."
  (match (io.open path "w")
    (nil msg) (println (.. "Could not open file: " msg))
    f (do
        (f:write content)
        (f:close)
        nil)))

(defn pr-str [...]
  (let [s (table.concat
            (map (fn [x]
                   (view.serialise x {:one-line true}))
                 [...])
            " ")]
    (if (or (not s) (= "" s))
      "nil"
      s)))

(defn pr [...]
  (println (pr-str ...)))

(defn merge [...]
  (reduce
    (fn [acc m]
      (when m
        (each [k v (pairs m)]
          (tset acc k v)))
      acc)
    {}
    [...]))

(defn select-keys [t ks]
  (if (and t ks)
    (reduce
      (fn [acc k]
        (when k
          (tset acc k (. t k)))
        acc)
      {}
      ks)
    {}))

;; TODO with-out-str
;; TODO get + get-in + set + set-in
