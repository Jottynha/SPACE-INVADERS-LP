-- title:   space_invaders
-- author:  Henrique,Joao,Pedro,Jader,Samuel
-- desc:    Derrote os alienigenas
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

-- Definir variáveis globais
player = {x = 100, y = 120, width = 8, height = 8, speed =2, lives = 3, immunity_timer = 0}
bullets = {}
enemies = {}
explosions = {}  -- Tabela para armazenar as animações de explosão
explosion_frames = {16, 17, 18, 19}  
explosion_duration = 10  -- Duração de cada frame da animação em contagem de ciclos
enemy_speed = 0.1  -- Diminui a velocidade dos inimigos
game_over = false
game_started = false
musica = false
t = 0
score = 0  -- Variável de pontuação
x = 96
y = 24

-- TIRO
special_weapon = {x = nil, y = nil, width = 8, height = 8, active = false, duration = 180, timer = 0}
local shot_cooldown = 10  -- Define o tempo de espera entre os tiros
local shot_timer = 0  -- Timer para controlar o tempo de espera

-- AREA DO JOGO
game_area_x = 40
game_area_y = 20
game_area_width = 160
game_area_height = 96

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
    local barrier_count = 3  -- Número de barreiras
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

-- Função para criar uma nova horda de inimigos
function spawn_enemy_wave()
    local enemy_count = 5  -- Número de inimigos a gerar
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
                is_fast = math.random() < 0.3 -- 30% de chance de ser rápido
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


-- Função para desenhar o jogador com sprite
function draw_player()
    if player.immunity_timer > 0 then
        player.immunity_timer = player.immunity_timer - 1  -- Diminui o temporizador de imunidade
        if t % 15 < 8 then  -- A cada 15 quadros, o jogador pisca
            spr(0, player.x, player.y, 0, 1, 0, 0, 1, 1) 
        end
    else
        spr(0, player.x, player.y, 0, 1, 0, 0, 1, 1) 
    end
    
end

-- Função para desenhar as balas
function draw_bullets()
    if special_weapon.active then
        for i, bullet in ipairs(bullets) do
            rect(bullet.x, bullet.y, 2, 4, 2)  -- cor das balas
        end  

    else
        for i, bullet in ipairs(bullets) do
            rect(bullet.x, bullet.y, 2, 4, 8)  -- cor das balas
        end
    end
end

-- Função para desenhar os inimigos
function draw_enemies()
    for i, enemy in ipairs(enemies) do
        local sprite_id = enemy.is_fast and 3 or 1  -- Se o inimigo for rápido, usa o sprite 3
        spr(sprite_id, enemy.x, enemy.y, 0, 1, 0, 0, 1, 1)  -- Desenha o inimigo com a cor correspondente
    end
end

function draw_special_weapon()
    if special_weapon.x then
        spr(2, special_weapon.x, special_weapon.y, 0, 1, 0, 0, 1, 1)
    end
end


-- Função para desenhar o score
function draw_score()
    print("Score: " .. score, 10, 10, 10)  -- Exibir a pontuação no canto superior esquerdo
    if(special_weapon.active) then 
        print("Special Weapon Active", 10, 20, 10) 
    end
    local life_icon_x = 60  
    for i = 1, player.lives do
        spr(4, life_icon_x, 10, 0, 1, 0, 0, 1, 1)  
        life_icon_x = life_icon_x + 12  -- Espaco entre os ícones de vida
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


-- Função para desenhar a borda ao redor do jogo
function draw_border()
    rect(game_area_x - 8, game_area_y - 8, game_area_width + 16, game_area_height + 16, 7)  -- borda em volta da área de jogo
end

-- Função para desenhar a tela inicial
function draw_start_screen()
    cls(0)  -- Cor de fundo preta
    -- Fundo decorado
    rect(0, 0, 240, 136, 0)  -- fundo com borda
    rect(10, 10, 220, 116, 7)  -- borda do jogo
    -- Título centralizado
    print("SPACE INVADERS", 80, 40, 10)
    
    -- Informações de controle
    print("CONTROLES:", 60, 60, 10)
    print("Seta Cima/Baixo: Movimenta", 40, 70, 10)
    print("Seta Esquerda/Direita: Movimenta", 40, 80, 10)
    print("Z: Atira", 40, 90, 10)
    print("X: Reiniciar após Game Over", 40, 100, 10)
    print("Pressione qualquer tecla para iniciar", 20, 110, 10)
end

-- Função para desenhar a tela de game over
function draw_game_over_screen()
    cls(0)  -- Cor de fundo preta
    -- Fundo decorado
    rect(0, 0, 240, 136, 0)  -- fundo com borda
    rect(10, 10, 220, 116, 7)  -- borda do jogo
    -- Texto de Game Over
    print("GAME OVER", 100, 60, 8)
    print("Pressione X para reiniciar", 40, 80, 8)  -- Mensagem para reiniciar
end

-- Função para mover o jogador
function move_player()
    if btn(0) then player.y = player.y - player.speed end  -- cima
    if btn(1) then player.y = player.y + player.speed end  -- baixo
    if btn(2) then player.x = player.x - player.speed end  -- esquerda
    if btn(3) then player.x = player.x + player.speed end  -- direita
    -- Limitar o movimento do jogador para não sair da tela
    if player.x < game_area_x then player.x = game_area_x end
    if player.x > game_area_x + game_area_width - player.width then player.x = game_area_x + game_area_width - player.width end
    if player.y < game_area_y then player.y = game_area_y end
    if player.y > game_area_y + game_area_height - player.height then player.y = game_area_y + game_area_height - player.height end
end

function spawn_special_weapon()
        special_weapon.x = game_area_x + math.random(0, game_area_width - special_weapon.width)
        special_weapon.y = game_area_y + math.random(0, game_area_height - special_weapon.height)
end

-- Função para atirar
function shoot()
    if btn(4) and shot_timer == 0 then  -- botão de atirar (Z) e se o tempo de espera for 0
        table.insert(bullets, {x = player.x + 3, y = player.y, width = 1, height = 2})  -- Tiro pequeno
        shot_timer = shot_cooldown  -- Reinicia o timer de cooldown
    end
end

function shoot_special()
    if btn(4) and shot_timer == 0 then  -- Botão de disparo (Z)
        table.insert(bullets, {x = player.x + 3, y = player.y, width = 2, height = 4}) -- Disparo central
        table.insert(bullets, {x = player.x - 3, y = player.y, width = 2, height = 4, dx = -1, dy = -1}) -- Diagonal esquerda
        table.insert(bullets, {x = player.x + 9, y = player.y, width = 2, height = 4, dx = 1, dy = -1}) -- Diagonal direita
        shot_timer = shot_cooldown
    end
end

function update_shooting()
    if shot_timer > 0 then
        shot_timer = shot_timer - 1  -- Decrementa o timer a cada quadro
    end
end


function move_bullets()
    for i, bullet in ipairs(bullets) do
        bullet.y = bullet.y - 4  -- Movimento vertical
        if bullet.dx then bullet.x = bullet.x + bullet.dx * 2 end -- Movimento diagonal
        if bullet.dy then bullet.y = bullet.y + bullet.dy * 2 end -- Movimento diagonal
        -- Verificar se a bala saiu da tela
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
    else
        shoot()  -- Disparo normal
    end
end

-- Função para mover os inimigos
function move_enemies()
    for i, enemy in ipairs(enemies) do
        if enemy.is_fast then
            enemy_speed = 0.3
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
        special_weapon.x = nil  -- Remove o item da tela
        special_weapon.y = nil
    end
end

-- Função para verificar colisões
function check_collisions()
    -- Verifica colisões entre balas e inimigos
    for i, bullet in ipairs(bullets) do
        for j, enemy in ipairs(enemies) do
            if bullet.x < enemy.x + enemy.width and bullet.x + bullet.width > enemy.x and
            bullet.y < enemy.y + enemy.height and bullet.y + bullet.height > enemy.y then
                -- Colisão entre bala e inimigo
                -- Adiciona a animação de explosão na posição do inimigo
                table.insert(explosions, {x = enemy.x, y = enemy.y, frame = 1, duration = explosion_duration})

                -- Remove o inimigo e a bala
                table.remove(bullets, i)
                table.remove(enemies, j)
                score = score + 10  -- Aumenta a pontuação
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
    draw_player()
    draw_bullets()
    draw_enemies()
    draw_special_weapon()
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

-- Função principal
function TIC()
    if not musica then
        initialize_barriers()
        music(1)
        musica = true
    end
    
    if not game_started then
        draw_start_screen()  -- Exibir tela inicial
        if btnp(4) or btnp(0) or btnp(1) or btnp(2) or btnp(3) then
            game_started = true  -- Iniciar o jogo quando qualquer tecla for pressionada
            create_enemies()  -- Criar inimigos
        end
    else
        if not game_over then
            -- Atualizar o jogo normalmente
            move_player()
            move_bullets()
            move_enemies()
            check_collisions()
            update_enemy_bullets()
            update_enemy_shooting()
            update_shooting()
            update_weapon()
            check_special_weapon_collision()
            
            -- Criar novas hordas ou armas especiais periodicamente
            if t % 120 == 0 then spawn_enemy_wave() end  -- A cada 3 segundos
            if t % 600 == 0 then spawn_special_weapon() end  -- A cada 10 segundos
            
        else
            -- Tela de Game Over
            cls()  -- Limpa a tela
            print("GAME OVER", 84, 60, 12)  -- Mensagem centralizada
            print("Pontuação: " .. score, 74, 80, 12)  -- Pontuação final
            print("Pressione X para reiniciar", 50, 100, 6)  -- Instruções
            
            -- Reiniciar o jogo ao pressionar X (botão 5)
            if btnp(5) then
                reset_game()
            end
        end
        
        draw_game()  -- Desenha o jogo em qualquer estado
    end
    
    t = t + 1  -- Incrementar o contador para animações
end

-- Função para reiniciar o jogo
function reset_game()
    game_over = false
    game_started = false
    score = 0  -- Resetar o score
    player.x = 100
    player.y = 120
    player.lives = 3
    bullets = {}
    enemies = {}
    enemy_bullets = {}
    barriers = {}
    initialize_barriers()  -- Reiniciar barreiras
    create_enemies()  -- Criar novos inimigos
end
