-- title:   space_invaders
-- author:  Henrique,Joao,Pedro,Jader,Samuel
-- desc:    Derrote os alienigenas
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

-- Definir variáveis globais
player = {x = 100, y = 120, width = 8, height = 8, speed =2, lives = 3, immunity_timer = 0}
player2 = {x = 120, y = 120, width = 8, height = 8, speed = 2, lives = 3, immunity_timer = 0, active = false}
bullets = {}
enemies = {}
life = {x = nil, y = nil, width = 8, height = 8}
explosions = {}  -- Tabela para armazenar as animações de explosão
explosion_frames = {16, 17, 18, 19, 20, 21, 22}  
explosion_duration = 10  -- Duração de cada frame da animação em contagem de ciclos
enemy_speed = 0.1  -- Diminui a velocidade dos inimigos
local enemy_count = 5  -- Número de inimigos a gerar
game_over = false
game_started = false
musica_menu = true
musica = false
control_music = false
t = 0
score = 0  -- Variável de pontuação
x = 96
y = 24

-- TIRO
special_weapon = {x = nil, y = nil, width = 8, height = 8, active = false, duration = 180, timer = 0, type= nil}
local shot_cooldown = 10  -- Define o tempo de espera entre os tiros
local shot_timer = 0  -- Timer para controlar o tempo de espera
local shot_timer_2 = 0 

-- AREA DO JOGO
game_area_x = 5
game_area_y = -20
game_area_width = 230
game_area_height = 192
local sprite_map = {} -- Tabela para armazenar os sprites da grade
local sprite_size = 8 
local sprite_ids = {8, 9, 10, 11, 12}
local initialized = false 
local offset = 0
local offset_speed = 0.1
local offset_counter = 0
was_hovered = false -- Variável para rastrear se o botão estava em "hover" no quadro anterior

-- ID dos efeitos sonoros
local id_hit = 16

--  INIMIGOS
enemy_direction = 1  -- Direção do movimento dos inimigos (1: para a direita, -1: para a esquerda)
enemy_move_counter = 0
enemy_bullets = {}
enemy_shoot_timer = 0
enemy_shoot_interval = 120  -- Inimigos atiram a cada 120 quadros (~2 segundos a 60 FPS)

-- BARREIRA
barriers = {}
local barrier_rows = 3
local barrier_cols = 8
local barrier_block_width = 4
local barrier_block_height = 3
local barrier_spacing = 20  -- Espaçamento entre as barreiras

function initialize_barriers()
    local barrier_count = 4  -- Número de barreiras
    local total_width = barrier_count * (barrier_cols * barrier_block_width) + (barrier_count - 1) * barrier_spacing
    local start_x = game_area_x + (game_area_width / 2) - (total_width / 2)
    local start_y = player.y - 26

    for b = 1, barrier_count do
        local barrier_start_x = start_x + (b - 1) * (barrier_cols * barrier_block_width + barrier_spacing)
        barriers[b] = {}

        for row = 1, barrier_rows do
            barriers[b][row] = {}
            for col = 1, barrier_cols do
                local is_u_shape = (row < barrier_rows) or (col == 1 or col == barrier_cols)
                barriers[b][row][col] = {
                    x = barrier_start_x + (col - 1) * barrier_block_width,
                    y = start_y + (row - 1) * barrier_block_height,
                    state = is_u_shape and 1 or 0 -- 1 para bloco ativo, 0 para espaço vazio
                }
            end
        end
    end
end

function draw_barriers()
    for b, barrier in ipairs(barriers) do
        for row = 1, #barrier do
            for col = 1, #barrier[row] do
                local block = barrier[row][col]
                if block.state > 0 then
                    spr(4 + (4 - block.state), block.x, block.y)  -- Usa sprites diferentes para estados
                end
            end
        end
    end
end

function update_barriers_on_collision()
    for b, barrier in ipairs(barriers) do
        for row = 1, #barrier do
            for col = 1, #barrier[row] do
                local block = barrier[row][col]
                if block.state > 0 then
                    -- Verifica se uma bala inimiga colidiu com o bloco
                    for i, bullet in ipairs(enemy_bullets) do
                        if bullet.x < block.x + barrier_block_width and bullet.x + bullet.width > block.x and
                           bullet.y < block.y + barrier_block_height and bullet.y + bullet.height > block.y then
                            -- Reduz o estado do bloco
                            block.state = block.state - 1
                            -- Remove a bala
                            table.remove(enemy_bullets, i)
                            break
                        end
                    end
                end
            end
        end
    end
end

function update_enemy_bullets()
    for i = #enemy_bullets, 1, -1 do
        local bullet = enemy_bullets[i]
        bullet.y = bullet.y + bullet.speed
        -- Remove a bala se sair da tela
        if bullet.y > game_area_y + game_area_height then
            table.remove(enemy_bullets, i)
        end
    end

    -- Atualizar colisões com barreiras
    update_barriers_on_collision()
end




-- Função para criar inimigos em uma formação centralizada
function create_enemies()
    enemies = {}  -- Limpar inimigos anteriores
    local start_x = game_area_x + (game_area_width - 5 * 16) / 2  -- Centraliza os inimigos horizontalmente
    for i = 1, 5 do
        for j = 1, 4 do  -- Ajustando a altura dos inimigos para subir
            table.insert(enemies, {x = start_x + (i - 1) * 16, y = game_area_y + (j - 1) * 12, width = 8, height = 8})
        end
    end
end

function spawn_boss()
    local enemy = {
        x = (game_area_x + game_area_width) / 2 - 16, -- Centro da tela, considerando largura do boss (64px)
        y = game_area_y, -- No topo da área de jogo
        width = 16, -- Boss ocupa 4 sprites (2x2), 64px de largura
        height = 16, -- 64px de altura
        health = 20, -- Precisa de 20 tiros para ser eliminado
        max_health = 20,
        sprites = {54, 55, 70, 71}, -- Sprites do boss
        speed = 0.2, -- Velocidade do movimento
        direction = 1, -- Direção horizontal (1 para direita, -1 para esquerda)
        is_boss = true
    }
    table.insert(enemies, enemy) -- Adiciona o boss na lista de inimigos
end


-- Função para criar uma nova horda de inimigos
function spawn_enemy_wave()
    local max_attempts = 50  -- Tentativas para evitar colisões

    for _ = 1, enemy_count do
        local spawned = false
        local attempts = 0

        while not spawned and attempts < max_attempts do
            attempts = attempts + 1

            -- Gera coordenadas aleatórias no topo da tela
            local new_enemy = {
                x = math.random(game_area_x, game_area_x + game_area_width - 8), -- Aleatório na largura
                y = game_area_y - 7,  -- Sempre no topo da tela
                width = 8,
                height = 8,
                is_fast = math.random() < 0.3, -- 30% de chance de ser rápido
                is_very_fast = math.random() < 0.1
            }

            -- Verifica se há colisão com outros inimigos
            local collision = false
            for _, enemy in ipairs(enemies) do
                if new_enemy.x < enemy.x + enemy.width and new_enemy.x + new_enemy.width > enemy.x and
                   new_enemy.y < enemy.y + enemy.height and new_enemy.y + new_enemy.height > enemy.y then
                    collision = true
                    break
                end
            end

            -- Se não houver colisão, adiciona o inimigo à lista
            if not collision then
                table.insert(enemies, new_enemy)
                spawned = true
            end
        end

        -- Caso não consiga posicionar após várias tentativas
        if attempts >= max_attempts then
            print("Falha ao posicionar todos os inimigos sem colisões.")
        end
    end
end

function draw_players()
    if player.immunity_timer > 0 then
        player.immunity_timer = player.immunity_timer - 1  -- Diminui o temporizador de imunidade
        if t % 15 < 8 then  -- A cada 15 quadros, o jogador pisca
            spr(player.direction, player.x, player.y, 0, 1, 0, 0, 1, 1) 
        end
    else
        spr(player.direction, player.x, player.y, 0, 1, 0, 0, 1, 1) 
    end

    if player2.active then
        if player2.immunity_timer > 0 then
            player2.immunity_timer = player2.immunity_timer - 1  -- Diminui o temporizador de imunidade
            if t % 15 < 8 then  -- A cada 15 quadros, o jogador pisca
                spr(player2.direction, player2.x, player2.y, 0, 1, 0, 0, 1, 1)  -- Sprites diferentes para diferenciar
            end
        else
            spr(player2.direction, player2.x, player2.y, 0, 1, 0, 0, 1, 1)  -- Desenha o segundo jogador
        end
    end
end

function draw_bullets()
    if special_weapon.active then
        for i, bullet in ipairs(bullets) do
            if bullet.trail then
                for j, trail in ipairs(bullet.trail) do
                    spr(53, trail.x, trail.y, 0, 1)  -- Aqui você pode mudar o sprite para o efeito de rastro
                end
            end
            spr(69, bullet.x, bullet.y, 0, 1)
        end
    end  
    if not special_weapon.active then
        for i, bullet in ipairs(bullets) do
            if bullet.trail then
                for j, trail in ipairs(bullet.trail) do
                    spr(53, trail.x, trail.y, 0, 1)  -- Aqui você pode mudar o sprite para o efeito de rastro
                end
            end
            spr(37, bullet.x, bullet.y, 0, 1)
        end
    end
end

function draw_enemies()
    for i, enemy in ipairs(enemies) do
        if enemy.is_boss then
            -- Desenha o boss como uma grade de 2x2 sprites
            draw_boss_health(enemy)
            spr(enemy.sprites[1], enemy.x, enemy.y,0, 1, 0, 0, 1, 1)                      -- Sprite superior esquerdo
            spr(enemy.sprites[2], enemy.x + 8, enemy.y,0, 1, 0, 0, 1, 1)                -- Sprite superior direito
            spr(enemy.sprites[3], enemy.x, enemy.y + 8,0, 1, 0, 0, 1, 1)                -- Sprite inferior esquerdo
            spr(enemy.sprites[4], enemy.x + 8, enemy.y + 8,0, 1, 0, 0, 1, 1)           -- Sprite inferior direito
        else
            -- Lógica para inimigos normais
            local sprite_id = enemy.is_very_fast and 38 or (enemy.is_fast and 3 or 1)
            spr(sprite_id, enemy.x, enemy.y, 0, 1, 0, 0, 1, 1)  -- Desenha o inimigo com o sprite correspondente
        end
    end
end

function draw_special_weapon()
    if special_weapon.x then
        spr(2, special_weapon.x, special_weapon.y, 0, 1, 0, 0, 1, 1)
    end
end

function draw_life()
    if life.x then
        spr(6, special_weapon.x, special_weapon.y, 0, 1, 0, 0, 1, 1)
    end
end

function rectfill(x1, y1, x2, y2, color)
    for y = y1, y2 do
        line(x1, y, x2, y, color)
    end
end


function draw_boss_health(boss)
    -- Posição do nome e da barra de vida
    local name_x = boss.x - 50 -- Centraliza o nome (boss.x + 8 pois o boss tem 16x16)
    local name_y = boss.y - 12 -- Ajusta a posição do nome acima do boss
    local bar_x = boss.x - 30   -- Centraliza a barra de vida
    local bar_y = boss.y - 6   -- A barra de vida aparece logo abaixo do nome
    
    -- Largura da barra de vida
    local bar_width = 64  -- Largura total da barra
    local bar_height = 4  -- Altura da barra
    local health_percentage = boss.health / boss.max_health -- Porcentagem de vida restante
    local filled_width = bar_width * health_percentage -- Largura preenchida
    
    -- Desenhar o nome do boss
    print("CRIATURA DAS PROFUNDEZAS", name_x, name_y, 7) -- Texto branco (cor 7)
    
    -- Desenhar a barra de vida
    rect(bar_x, bar_y, bar_width, bar_height, 15)         -- Fundo da barra (preto)
    rectfill(bar_x, bar_y, bar_x + filled_width, bar_y + bar_height, 3) -- Parte preenchida (vermelho)
end


function update_offset()
    offset_counter = offset_counter + offset_speed
    if offset_counter >= 1 then
        offset_counter = 0 
        offset = offset + 1
        if offset > 2 then
            offset = 0
        end
    end
end

function draw_score()
    update_offset()
    print("Score: " .. score, 10, 10 + offset, 10)  
    if special_weapon.active then 
        print("Special Weapon Active", 10, 20 + offset, 10) 
    end
    local life_icon_x = 160  
    for i = 1, player.lives do
        spr(4, life_icon_x, 8 + offset, 0, 1, 0, 0, 1, 1)  
        life_icon_x = life_icon_x + 12  -- Espaço entre os ícones de vida
    end
    if player2.active then
        local life_icon_x = 110 
        for i = 1, player2.lives do
            spr(5, life_icon_x, 8 + offset, 0, 1, 0, 0, 1, 1)  
            life_icon_x = life_icon_x + 12  -- Espaço entre os ícones de vida
        end
    end
end


function player_loses_life()
    if player.lives > 0 and player.immunity_timer == 0 then
        player.lives = player.lives - 1  -- Diminui uma vida
        player.immunity_timer = 180  -- 180 quadros = 3 segundos de imunidade
    end
    
    if player.lives == 0 then
        game_over = true  -- Acaba o jogo quando as vidas chegam a 0
    end
end

function player_loses_life_2()
    if player2.lives > 0 and player2.immunity_timer == 0 then
        player2.lives = player2.lives - 1  -- Diminui uma vida
        player2.immunity_timer = 180  -- 180 quadros = 3 segundos de imunidade
    end
    
    if player2.lives == 0 then
        game_over = true  -- Acaba o jogo quando as vidas chegam a 0
    end
end

function initialize_map()
    -- Calcula o número de colunas e linhas
    local cols = math.ceil(game_area_width / sprite_size)
    local rows = math.ceil(game_area_height / sprite_size)
    
    -- Preenche o mapa com sprites aleatórios
    for row = 0, rows - 1 do
        sprite_map[row] = {}
        for col = 0, cols - 1 do
            sprite_map[row][col] = sprite_ids[math.random(#sprite_ids)]
        end
    end
    
    initialized = true -- Marca como inicializado
end

function draw_border()
    if not initialized then
        initialize_map() -- Inicializa o mapa apenas uma vez
    end

    -- Desenha o mapa com base nos valores armazenados
    for row, cols in pairs(sprite_map) do
        for col, sprite in pairs(cols) do
            local x = game_area_x + col * sprite_size
            local y = game_area_y + row * sprite_size
            spr(sprite, x, y, 0)
        end
    end
end

function draw_start_screen()
    rect(0, 0, 240, 136, 1) -- Borda externa
    rect(5, 5, 230, 126, 0) -- Fundo interno
    local start_id = 32 -- ID inicial
    for row = 0, 3 do
        for col = 0, 3 do
            local sprite_id = start_id + row * 16 + col
            spr(sprite_id, 100 + col * sprite_size, 20 + row * sprite_size, 0, 1, 0, 0)
        end
    end

    local mx, my, click = mouse()
    local is_clicked, is_hovered = button_clicked(110, 60, 100, 20, "NOVO JOGO", mx, my, click)
    local text_color = is_hovered and 15 or 10 -- Branco se colidido, preto caso contrário

    -- Reproduzir som ao passar o mouse por cima, com duração de 15 ticks (0.25 segundos)
    if is_hovered and not was_hovered then
        sfx(0, "D#5", 15, 0, 15) -- ID 0, nota padrão (-1), duração de 15 ticks no canal 0
    elseif not is_hovered and was_hovered then
        sfx(-1, 0) -- Para o som no canal 0 quando o hover termina
    end
    was_hovered = is_hovered

    draw_button(110, 60, 1, 1, "NOVO JOGO", 12, text_color)
    print("CONTROLES:", 10, 70, 10)
    print("- Setas: Movimentacao do Player 1", 10, 80, 6)
    print("- Seta para Cima: Atirar do Player 1", 10, 90, 6)
    print("- A & D: Movimentacao do Player 2", 10, 100, 6)
    print("- W: Atirar do Player 2", 10, 110, 6)
    print("- X: Ativar Multiplayer", 10, 120, 6)    

    -- Reproduzir som ao clicar, com duração de 20 ticks (0.33 segundos)
    if is_clicked then
        control_music = true
        sfx(1, "F#6", 20, 1, 15)
        game_started = true  
        create_enemies()  
    end
    spr(238, 219, 115)
    spr(239, 227, 115)
    spr(254, 219, 123)
    spr(255, 227, 123)
end

function draw_button(x, y, w, h, text, bg_color, text_color)
    rect(x, y, w, h, bg_color)
    local char_width = 4  
    local text_width = #text * char_width
    local text_height = 6 
    local text_x = x + (w - text_width) // 2
    local text_y = y + (h - text_height) // 2
    print(text, text_x, text_y, text_color)
end


function button_clicked(x, y, w, h, text, mx, my, click)
    -- Define os limites baseados no texto
    local char_width = 4
    local text_width = #text * char_width
    local text_x = x + (w - text_width) // 2
    local text_right = text_x + text_width

    -- Ajusta os limites clicáveis (opcionalmente inclui um "padding" ao redor do botão)
    local padding = 2
    local button_left = math.min(x, text_x) - padding
    local button_right = math.max(x + w, text_right) + padding
    local button_top = y - padding
    local button_bottom = y + h + padding

    -- Verifica colisão considerando o texto e os limites ajustados
    local is_hovered = mx >= button_left and mx < button_right and my >= button_top and my < button_bottom
    local is_clicked = is_hovered and click

    -- Retorna se o botão foi clicado e se o mouse está sobre ele
    return is_clicked, is_hovered
end

-- Função para desenhar a tela de game over
function draw_game_over_screen()
    rect(0, 0, 240, 136, 0)  -- fundo com borda
    rect(10, 10, 220, 116, 0)  -- borda do jogo
    -- Texto de Game Over
    print("GAME OVER", 90, 40, 8)
    print("Score: " .. score, 90, 50, 8)
    local mx, my, click = mouse()
    local is_clicked, is_hovered = button_clicked(110, 60, 100, 20, "REINICIAR", mx, my, click)
    local text_color = is_hovered and 15 or 10
    draw_button(110, 60, 1, 1, "REINICIAR", 12, text_color)
    if button_clicked(110, 60, 20, 20, "REINICIAR", mx, my, click) then
        reset_game()
    end
end

function move_player()
    local moved = false -- Variável para rastrear se o jogador se moveu
    if btn(2) then -- Esquerda
        player.x = player.x - player.speed
        player.direction = 14 -- Define o sprite para a direção esquerda
        moved = true
    end
    if btn(3) then -- Direita
        player.x = player.x + player.speed
        player.direction = 13 -- Define o sprite para a direção direita
        moved = true
    end
    if not moved then
        player.direction = 0
    end
    if player.x < game_area_x then player.x = game_area_x end
    if player.x > game_area_x + game_area_width - player.width then 
        player.x = game_area_x + game_area_width - player.width 
    end
    if player.y < game_area_y then player.y = game_area_y end
    if player.y > game_area_y + game_area_height - player.height then 
        player.y = game_area_y + game_area_height - player.height 
    end
end

function move_player2()
    local moved = false 
    if btn(0) then
        player2.x = player2.x - player2.speed
        player2.direction = 24 -- Sprite para a esquerda
        moved = true
    end
    if btn(1) then
        player2.x = player2.x + player2.speed
        player2.direction = 23 -- Sprite para a direita
        moved = true
    end
    if player2.x < game_area_x then
        player2.x = game_area_x
    end
    if player2.x + player2.width > game_area_x + game_area_width then
        player2.x = game_area_x + game_area_width - player2.width
    end
    if player2.y < game_area_y then
        player2.y = game_area_y
    end
    if player2.y + player2.height > game_area_y + game_area_height then
        player2.y = game_area_y + game_area_height - player2.height
    end
    if not moved then
        player2.direction = 15
    end
end

function spawn_special_weapon()
        special_weapon.x = game_area_x + math.random(0, game_area_width - special_weapon.width)
        special_weapon.y = player.y
end

function spawn_life()
    life.x = game_area_x + math.random(0, game_area_width - life.width)
    life.y = player.y
end

-- Função para atirar
function shoot()
    if btn(6) and shot_timer == 0 then  -- botão de atirar (Z) e se o tempo de espera for 0
        table.insert(bullets, {x = player.x + 3, y = player.y, width = 8, height = 8})  -- Tiro pequeno
        sfx(2, "B-6", 2, 1, 3, 1)
        shot_timer = shot_cooldown  -- Reinicia o timer de cooldown
    end
end

function shoot_player2()
    if btn(4) and shot_timer_2 == 0 and player2.active then  -- botão de atirar (Z) e se o tempo de espera for 0
        table.insert(bullets, {x = player2.x + 3, y = player2.y, width = 1, height = 2})  -- Tiro pequeno
        sfx(2, "B-6", 2, 1, 3, 1)
        shot_timer_2 = shot_cooldown  -- Reinicia o timer de cooldown
    end
end

function randomize_special_weapon_type()
    special_weapon.type = math.random(1, 3)  -- Randomiza entre 1 e 3
end

function shoot_special()
    if btn(6) and shot_timer == 0 then 
        if special_weapon.type == 1 then  -- Tipo 1: Tiro triplo
            table.insert(bullets, {x = player.x + 3, y = player.y, width = 8, height = 8}) -- Disparo central
            table.insert(bullets, {x = player.x - 3, y = player.y, width = 8, height = 8, dx = -1, dy = -1}) -- Diagonal esquerda
            table.insert(bullets, {x = player.x + 9, y = player.y, width = 8, height = 8, dx = 1, dy = -1}) -- Diagonal direita
        elseif special_weapon.type == 2 then  -- Tipo 2: Tiro duplo reto
            table.insert(bullets, {x = player.x + 3, y = player.y, width = 8, height = 8}) -- Disparo central
            table.insert(bullets, {x = player.x + 9, y = player.y, width = 8, height = 8}) -- Disparo à direita
        elseif special_weapon.type == 3 then  -- Tipo 3: Tiro em ângulo
            table.insert(bullets, {x = player.x + 3, y = player.y, width = 8, height = 8, dx = 1, dy = -1}) -- Diagonal direita
            table.insert(bullets, {x = player.x + 9, y = player.y, width = 8, height = 8, dx = -1, dy = -1}) -- Diagonal esquerda
        end

        sfx(2, "C-6", 2, 1, 3, 1)
        shot_timer = shot_cooldown
    end
end

function shoot_special_2()
    if btn(4) and shot_timer_2 == 0 and player2.active then 
        if special_weapon.type == 1 then  -- Tipo 1: Tiro triplo
            table.insert(bullets, {x = player2.x + 3, y = player2.y, width = 2, height = 4}) -- Disparo central
            table.insert(bullets, {x = player2.x - 3, y = player2.y, width = 2, height = 4, dx = -1, dy = -1}) -- Diagonal esquerda
            table.insert(bullets, {x = player2.x + 9, y = player2.y, width = 2, height = 4, dx = 1, dy = -1}) -- Diagonal direita
        elseif special_weapon.type == 2 then  -- Tipo 2: Tiro duplo reto
            table.insert(bullets, {x = player2.x + 3, y = player2.y, width = 2, height = 4}) -- Disparo central
            table.insert(bullets, {x = player2.x + 9, y = player2.y, width = 2, height = 4}) -- Disparo à direita
        elseif special_weapon.type == 3 then  -- Tipo 3: Tiro em ângulo
            table.insert(bullets, {x = player2.x + 3, y = player2.y, width = 2, height = 4, dx = 1, dy = -1}) -- Diagonal direita
            table.insert(bullets, {x = player2.x + 9, y = player2.y, width = 2, height = 4, dx = -1, dy = -1}) -- Diagonal esquerda
        end

        sfx(2, "C-6", 2, 1, 3, 1) 
        shot_timer_2 = shot_cooldown
    end
end

function update_shooting()
    if shot_timer > 0 then
        shot_timer = shot_timer - 1  -- Decrementa o timer a cada quadro
    end
    if shot_timer_2 > 0 then
        shot_timer_2 = shot_timer_2 - 1  -- Decrementa o timer a cada quadro
    end
end


function move_bullets()
    for i, bullet in ipairs(bullets) do
        if not bullet.trail then
            bullet.trail = {}  -- Cria a tabela de rastro
        end
        bullet.y = bullet.y - 4  
        if bullet.dx then bullet.x = bullet.x + bullet.dx * 2 end
        if bullet.dy then bullet.y = bullet.y + bullet.dy * 2 end
        table.insert(bullet.trail, {x = bullet.x, y = bullet.y}) 
        if #bullet.trail > 5 then
            table.remove(bullet.trail, 1)
        end
        if bullet.y < game_area_y or bullet.x < game_area_x or bullet.x > game_area_x + game_area_width then
            table.remove(bullets, i)
        end
    end
end

function update_weapon()
    if special_weapon.active then
        special_weapon.timer = special_weapon.timer - 1
        if special_weapon.timer <= 0 then
            special_weapon.active = false
        end
    end
    
    if special_weapon.active then
        shoot_special()  -- Ativar disparo especial
        shoot_special_2()  -- Ativar disparo especial
    else
        shoot()  -- Disparo normal
        shoot_player2()
    end
end

-- Função para mover os inimigos
function move_enemies()
    for i, enemy in ipairs(enemies) do
        if enemy.is_fast then
            enemy_speed = 0.3
        end
        if enemy.is_very_fast then
            enemy_speed = 0.6    
        else
            enemy_speed = 0.1
        end
        enemy.x = enemy.x + enemy_direction * enemy_speed
    end

    enemy_move_counter = enemy_move_counter + 1
    if enemy_move_counter > 60 then
        enemy_move_counter = 0
        enemy_direction = -enemy_direction
        -- Descer os inimigos
        for i, enemy in ipairs(enemies) do
            -- Se o inimigo for rápido, descer mais rápido
            if enemy.is_fast then
                enemy.y = enemy.y + 12  -- Inimigos rápidos descem mais (ex: 12 pixels)
            end
            if enemy.is_very_fast then
                enemy.y = enemy.y + 18  
            else
                enemy.y = enemy.y + 8   -- Inimigos normais descem 8 pixels
            end
        end
    end

    -- Fim do jogo se inimigos chegarem ao fundo
    for i, enemy in ipairs(enemies) do
        if enemy.y > game_area_y + game_area_height - 8 then
            game_over = true
            break
        end
    end
end

function check_special_weapon_collision()
    if special_weapon.x and player.x < special_weapon.x + special_weapon.width and
       player.x + player.width > special_weapon.x and
       player.y < special_weapon.y + special_weapon.height and
       player.y + player.height > special_weapon.y then
        special_weapon.active = true
        special_weapon.timer = special_weapon.duration
        special_weapon.x = nil  
        special_weapon.y = nil
    end
    if special_weapon.x and player2.active and player2.x < special_weapon.x + special_weapon.width and
       player2.x + player2.width > special_weapon.x and
       player2.y < special_weapon.y + special_weapon.height and
       player2.y + player2.height > special_weapon.y then
        special_weapon.active = true
        special_weapon.timer = special_weapon.duration
        special_weapon.x = nil  
        special_weapon.y = nil
    end
end

function check_life_collision()
    if life.x and player.x < life.x + life.width and
       player.x + player.width > life.x and
       player.y < life.y + life.height and
       player.y + player.height > life.y then
        player.lives = player.lives + 1
        life.x = nil  
        life.y = nil
    end
    if life.x and player2.active and player2.x < life.x + life.width and
       player2.x + player2.width > life.x and
       player2.y < life.y + life.height and
       player2.y + player2.height > life.y then
        player2.lives = player2.lives + 1
        life.x = nil  
        life.y = nil
    end
end

function check_collisions()
    -- Verifica colisões entre balas e inimigos
    for i, bullet in ipairs(bullets) do
        for j, enemy in ipairs(enemies) do
            if bullet.x < enemy.x + enemy.width and bullet.x + bullet.width > enemy.x and
               bullet.y < enemy.y + enemy.height and bullet.y + bullet.height > enemy.y then
                if enemy.health and enemy.health > 0 then
                    enemy.health = enemy.health - 1 -- Diminui a saúde do boss
                    if enemy.health <= 0 then
                        table.insert(explosions, {x = enemy.x, y = enemy.y, frame = 1, duration = explosion_duration})
                        table.remove(enemies, j)
                        sfx(id_hit) -- Toca som de eliminação
                        score = score + 100 -- Pontuação maior para o boss
                    end
                else
                    table.insert(explosions, {x = enemy.x, y = enemy.y, frame = 1, duration = explosion_duration})
                    table.remove(enemies, j)
                    score = score + 10 -- Pontuação normal para inimigos comuns
                end
                table.remove(bullets, i)
                break
            end
        end
    end
    

    -- Verifica colisões entre o jogador e inimigos
    for i, enemy in ipairs(enemies) do
        if player.x < enemy.x + enemy.width and player.x + player.width > enemy.x and
           player.y < enemy.y + enemy.height and player.y + player.height > enemy.y then
            player_loses_life()

            break
        end
    end
end

function draw_explosions()
    for i, explosion in ipairs(explosions) do
        -- Desenha o frame da explosão baseado no índice (frame)
        spr(explosion_frames[explosion.frame], explosion.x, explosion.y, 0, 1, 0, 0, 1, 1)

        -- Atualiza o frame da animação
        explosion.duration = explosion.duration - 1
        if explosion.duration <= 0 then
            -- Se a duração terminar, remove a explosão
            table.remove(explosions, i)
        else
            -- Atualiza para o próximo frame
            explosion.frame = explosion.frame + 1
            if explosion.frame > #explosion_frames then
                explosion.frame = 1
            end
        end
    end
end


-- Função para desenhar o estado do jogo
function draw_game()
    cls(0)  -- Limpar tela com fundo preto
    draw_border()
    draw_players()
    draw_bullets()
    draw_enemies()
    draw_special_weapon()
    draw_life()
    draw_score()  -- Exibe o score
    draw_explosions()
    draw_barriers()
    draw_enemy_bullets()
    if game_over then
        draw_game_over_screen()  -- Exibe a tela de Game Over
    end
end

-- Função para disparar tiros dos inimigos
function enemy_shoot(enemy)
    local bullet = {
        x = enemy.x + enemy.width / 2 - 1,
        y = enemy.y + enemy.height,
        width = 2,
        height = 4,
        speed = 1
    }
    table.insert(enemy_bullets, bullet)
end

-- Atualizar os tiros dos inimigos
function update_enemy_bullets()
    for i = #enemy_bullets, 1, -1 do
        local bullet = enemy_bullets[i]
        bullet.y = bullet.y + bullet.speed

        -- Verifica colisão com barreiras
        if update_barriers_on_collision(bullet) then
            table.remove(enemy_bullets, i)
        elseif bullet.y > game_area_y + game_area_height then
            table.remove(enemy_bullets, i)  -- Remove tiros fora da tela
        end

        -- Verifica colisão com o jogador
        if bullet.x < player.x + player.width and bullet.x + bullet.width > player.x and
           bullet.y < player.y + player.height and bullet.y + bullet.height > player.y then
            player_loses_life()
            table.remove(enemy_bullets, i)
            break
        end
        if player2.active and bullet.x < player2.x + player2.width and bullet.x + bullet.width > player2.x and
           bullet.y < player2.y + player2.height and bullet.y + bullet.height > player2.y then
            player_loses_life_2()
            table.remove(enemy_bullets, i)
            break
        end
    end
end

-- Atualizar disparos dos inimigos periodicamente
function update_enemy_shooting()
    enemy_shoot_timer = enemy_shoot_timer + 1
    if enemy_shoot_timer >= enemy_shoot_interval then
        enemy_shoot_timer = 0

        -- Escolhe inimigos aleatórios para atirar
        for _, enemy in ipairs(enemies) do
            if math.random() < 0.3 then  -- 30% de chance de atirar
                enemy_shoot(enemy)
            end
        end
    end
end

-- Função para desenhar tiros dos inimigos
function draw_enemy_bullets()
    for _, bullet in ipairs(enemy_bullets) do
        rect(bullet.x, bullet.y, bullet.width, bullet.height, 8)  -- Cor 8 para vermelho
    end
end

function active_player2()
    player2.active = true
end

function TIC()
    if not musica and control_music  then
        initialize_barriers()
        music(7)
        music(1)
        musica = true
    end
    if btn(5) then active_player2() end
    if not game_started then
        if musica_menu and not control_music then
            music(2)
            musica_menu = false
        end 
        draw_start_screen()
    else
        if not game_over then
            
            -- Atualizar o jogo normalmente
            move_player()
            if player2.active then move_player2() end
            move_bullets()
            move_enemies()
            check_collisions()
            update_enemy_bullets()
            update_enemy_shooting()
            update_shooting()
            update_weapon()
            check_special_weapon_collision()
            check_life_collision()
            
            if player.lives == 0 or player2.lives == 0 then
                game_over = true
            end

            if t % 120 == 0 then spawn_enemy_wave() end  -- A cada 3 segundos
            if t % 600 == 0 then 
                spawn_special_weapon() 
                randomize_special_weapon_type()
                enemy_count = enemy_count + 1
            end  -- A cada 10 segundos
            if t% 800 == 0 then spawn_life() end
            if t% 900 == 0 then spawn_boss() end
        end
        
        draw_game()  -- Desenha o jogo em qualquer estado
    end
    
    t = t + 1  -- Incrementar o contador para animações
end

-- Função para reiniciar o jogo
function reset_game()
    game_over = false
    game_started = false
    score = 0  
    player.x = 100
    player.y = 120
    player.lives = 3
    player2.lives = 3
    bullets = {}
    enemies = {}
    enemy_bullets = {}
    barriers = {}
    initialize_barriers()  -- Reiniciar barreiras
    create_enemies()  -- Criar novos inimigos
end
