(ns spec-test.performance)

(def o (Object.))
(def mut (volatile! 0))

(defmacro do-parallel [n f]
  (let [fut-bindings
        (for [i (range n)
              sym [(symbol (str "fut_" i))
                   `(future (locking o (vswap! mut ~f)))]]
          sym)
        fut-names (vec (take-nth 2 fut-bindings))]
    `(let [~@fut-bindings] ;; start all futures
       (doseq [f# ~fut-names] ;; wait for all futures
         @f#))))

(defn -main [& _args]
  (println "Java version:" (System/getProperty "java.version"))
  (println "Clojure version:" (clojure-version))

  ;; measure time running 10k times incrementing mut 1k times in parallel
  (time (dotimes [_ 10000] (do-parallel 1000 inc)))

  (println @mut) ;; should be 10000000
  (shutdown-agents))
