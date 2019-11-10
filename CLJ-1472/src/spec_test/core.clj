(ns spec-test.core
  (:gen-class)
  (:require [clojure.spec.alpha :as s]))

(s/def ::g int?)

(defn -main [& _args]
  (println *clojure-version*)
  (println (s/valid? ::g 1)))
