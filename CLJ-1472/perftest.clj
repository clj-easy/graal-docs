#!/usr/bin/env bb

(defn run-lock-test [{:keys [deps-version-alias jvm-opt]}]
  (let [cmd (remove nil?
                    ["clojure"
                     jvm-opt
                     (str "-A:performance:" deps-version-alias)])
        _ (println "-> running:" (apply str (interpose " " cmd)))
        {:keys [:exit :err :out]} (apply shell/sh cmd)]
    (if (zero? exit)
      (do
        (println out)
        out)
      (do (println "* ERROR running test")
          (println "exit code:" exit)
          (println "\nstderr:")
          (println err)
          (println "\nstdout:")
          (println out)
          (System/exit exit)))))

(defn parse-lock-test-result [res]
  (->> res
       (re-matches #"(?s)^Java version: (.*)\nClojure version: (.*)\n\"Elapsed time: (.*) msecs\".*")
       rest
       (zipmap [:java-version :clojure-version :elapsed-msecs])))

(defn lock-test [opts]
  (merge opts (parse-lock-test-result (run-lock-test opts))))

(defn create-result-table [res]
  (let [clojure-versions (sort (distinct (map :clojure-version res)))
        header (into ["Java Version" "JVM Opt"] clojure-versions)
        rows (->> res
                  (group-by (juxt :java-version :jvm-opt))
                  (map (fn [[java-cols timings]]
                         (into java-cols
                               (map :elapsed-msecs
                                    (map (fn [header-version]
                                           (first (filter #(= (:clojure-version %) header-version) timings)))
                                         clojure-versions))))))]
    (concat [header] rows)))

(defn format-long-versions-to-wrap [text]
  (.replace text "_" " "))

(defn format-hyphens-not-to-wrap [text]
  (.replace text "-" "&#x2011;"))

(defn markdown-table-row [row]
  (concat ["| "]
          (interpose " | "
                     (map #(if (nil? %)
                             "&lt;none&gt;"
                             (format-hyphens-not-to-wrap %))
                          row))
          [" |\n"]))

(defn markdown-header-sep [num-cols]
  (concat ["|"]
          (interpose "|" (repeat num-cols "---"))
          ["|\n"]))

(defn results-table->markdown [results-table]
  (->> (concat [(markdown-table-row (map format-long-versions-to-wrap (first results-table)))]
               [(markdown-header-sep (count (first results-table)))]
               (map markdown-table-row (rest results-table)))
       (map #(apply str %))
       (apply str)))

(defn as-markdown [res]
  (results-table->markdown (create-result-table res)))

(let [results (into [] (for [alias ["1.10.1" "1472-patch-5" "1472-reentrant" "1472-patch-4" ]
                             opt [nil "-J-XX:-EliminateLocks"]]
                       (lock-test {:deps-version-alias alias :jvm-opt opt})))]
  (println (str "\nresults as edn:\n" results))
  (println (str "\nresults as markdown:\n" (as-markdown results))))
