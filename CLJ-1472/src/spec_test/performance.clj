(ns spec-test.performance)

(def o (Object.))
(def mut (int-array 1))

(defmacro do-parallel [n]
  (let [fut-bindings
        (for [i (range n)
              sym [(symbol (str "fut_" i))
                   `(future (locking o (aset mut 0 (inc (long (aget mut 0))))))]]
          sym)
        fut-names (vec (take-nth 2 fut-bindings))]
    `(let [~@fut-bindings] ;; start all futures
       (doseq [f# ~fut-names] ;; wait for all futures
         @f#))))

(defn -main [& _args]
  (println "Java version:" (System/getProperty "java.version"))
  (println "Clojure version:" (clojure-version))

  (time (dotimes [_ 10000] (do-parallel 100)))
  (assert (= (aget mut 0) (* 10000 100)) (str "unexpected mutation count: " (aget mut 0)))
  (println "Success")
  (shutdown-agents))
