Многоядерный RISC Процессор (текущий проект).
На основе однотактного MIPS будет создан многоядерный процессор. В данный момент были
внесены изменения в ядро. Был добавлен сопроцессор 0 для выполнения спец. команд в
режиме супервизора. Конвейеризирован тракт данных ( 5 частей) и добавлен блок разрешения
конфликтов. Создан буфер ассоциативной трансляции для виртуальной памяти и кэш. В
дальнеишем предполагается создание контролера, реализующего алгоритм наблюдения, для
подержания когерентности и согласованности памяти.