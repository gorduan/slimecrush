/**
 * SlimeCrush - A Candy Crush inspired match-3 game
 * Mobile-first HTML/JS implementation
 */

class SlimeCrush {
    constructor() {
        // Board configuration
        this.BOARD_SIZE = 8;
        this.COLORS = ['red', 'orange', 'yellow', 'green', 'blue', 'purple'];

        // Special types
        this.SPECIAL = {
            NONE: 'none',
            STRIPED_H: 'striped-h',  // Horizontal striped
            STRIPED_V: 'striped-v',  // Vertical striped
            WRAPPED: 'wrapped',       // Wrapped candy
            COLOR_BOMB: 'color-bomb'  // Color bomb (matches 5 in a row)
        };

        // Game state
        this.board = [];
        this.score = 0;
        this.moves = 30;
        this.level = 1;
        this.targetScore = 1000;
        this.selectedCell = null;
        this.isAnimating = false;
        this.comboCount = 0;

        // Touch handling
        this.touchStartX = 0;
        this.touchStartY = 0;
        this.touchStartCell = null;
        this.SWIPE_THRESHOLD = 30;

        // DOM elements
        this.boardElement = document.getElementById('game-board');
        this.scoreElement = document.getElementById('score');
        this.movesElement = document.getElementById('moves');
        this.levelElement = document.getElementById('level');
        this.comboDisplay = document.getElementById('combo-display');

        this.init();
    }

    init() {
        this.createBoard();
        this.renderBoard();
        this.setupEventListeners();
        this.updateUI();
    }

    // Create initial board without matches
    createBoard() {
        this.board = [];
        for (let row = 0; row < this.BOARD_SIZE; row++) {
            this.board[row] = [];
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                let color;
                do {
                    color = this.getRandomColor();
                } while (this.wouldCreateMatch(row, col, color));

                this.board[row][col] = {
                    color: color,
                    special: this.SPECIAL.NONE
                };
            }
        }
    }

    // Check if placing a color would create a match
    wouldCreateMatch(row, col, color) {
        // Check horizontal
        if (col >= 2) {
            if (this.board[row][col-1]?.color === color &&
                this.board[row][col-2]?.color === color) {
                return true;
            }
        }
        // Check vertical
        if (row >= 2) {
            if (this.board[row-1]?.[col]?.color === color &&
                this.board[row-2]?.[col]?.color === color) {
                return true;
            }
        }
        return false;
    }

    getRandomColor() {
        return this.COLORS[Math.floor(Math.random() * this.COLORS.length)];
    }

    // Render the game board
    renderBoard() {
        this.boardElement.innerHTML = '';

        for (let row = 0; row < this.BOARD_SIZE; row++) {
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                const cell = document.createElement('div');
                cell.className = 'cell';
                cell.dataset.row = row;
                cell.dataset.col = col;

                const slime = this.board[row][col];
                if (slime) {
                    const slimeElement = document.createElement('div');
                    slimeElement.className = `slime ${slime.color}`;

                    if (slime.special !== this.SPECIAL.NONE) {
                        slimeElement.classList.add(slime.special);
                    }

                    cell.appendChild(slimeElement);
                }

                this.boardElement.appendChild(cell);
            }
        }
    }

    // Update a single cell
    updateCell(row, col) {
        const index = row * this.BOARD_SIZE + col;
        const cell = this.boardElement.children[index];
        if (!cell) return;

        cell.innerHTML = '';
        const slime = this.board[row][col];

        if (slime) {
            const slimeElement = document.createElement('div');
            slimeElement.className = `slime ${slime.color}`;

            if (slime.special !== this.SPECIAL.NONE) {
                slimeElement.classList.add(slime.special);
            }

            cell.appendChild(slimeElement);
        }
    }

    // Setup event listeners
    setupEventListeners() {
        // Touch events for mobile
        this.boardElement.addEventListener('touchstart', (e) => this.handleTouchStart(e), { passive: false });
        this.boardElement.addEventListener('touchmove', (e) => this.handleTouchMove(e), { passive: false });
        this.boardElement.addEventListener('touchend', (e) => this.handleTouchEnd(e));

        // Mouse events for desktop
        this.boardElement.addEventListener('mousedown', (e) => this.handleMouseDown(e));
        this.boardElement.addEventListener('mouseup', (e) => this.handleMouseUp(e));
        this.boardElement.addEventListener('click', (e) => this.handleClick(e));
    }

    getCellFromEvent(e) {
        const target = e.target.closest('.cell');
        if (!target) return null;
        return {
            row: parseInt(target.dataset.row),
            col: parseInt(target.dataset.col),
            element: target
        };
    }

    handleTouchStart(e) {
        if (this.isAnimating) return;
        e.preventDefault();

        const touch = e.touches[0];
        this.touchStartX = touch.clientX;
        this.touchStartY = touch.clientY;
        this.touchStartCell = this.getCellFromEvent(touch);
    }

    handleTouchMove(e) {
        e.preventDefault();
    }

    handleTouchEnd(e) {
        if (this.isAnimating || !this.touchStartCell) return;

        const touch = e.changedTouches[0];
        const deltaX = touch.clientX - this.touchStartX;
        const deltaY = touch.clientY - this.touchStartY;

        // Check if it's a swipe
        if (Math.abs(deltaX) > this.SWIPE_THRESHOLD || Math.abs(deltaY) > this.SWIPE_THRESHOLD) {
            let targetRow = this.touchStartCell.row;
            let targetCol = this.touchStartCell.col;

            if (Math.abs(deltaX) > Math.abs(deltaY)) {
                // Horizontal swipe
                targetCol += deltaX > 0 ? 1 : -1;
            } else {
                // Vertical swipe
                targetRow += deltaY > 0 ? 1 : -1;
            }

            if (this.isValidPosition(targetRow, targetCol)) {
                this.trySwap(this.touchStartCell.row, this.touchStartCell.col, targetRow, targetCol);
            }
        } else {
            // Tap - select cell
            this.handleCellSelect(this.touchStartCell.row, this.touchStartCell.col);
        }

        this.touchStartCell = null;
    }

    handleMouseDown(e) {
        if (this.isAnimating) return;
        const cell = this.getCellFromEvent(e);
        if (cell) {
            this.touchStartX = e.clientX;
            this.touchStartY = e.clientY;
            this.touchStartCell = cell;
        }
    }

    handleMouseUp(e) {
        if (this.isAnimating || !this.touchStartCell) return;

        const deltaX = e.clientX - this.touchStartX;
        const deltaY = e.clientY - this.touchStartY;

        if (Math.abs(deltaX) > this.SWIPE_THRESHOLD || Math.abs(deltaY) > this.SWIPE_THRESHOLD) {
            let targetRow = this.touchStartCell.row;
            let targetCol = this.touchStartCell.col;

            if (Math.abs(deltaX) > Math.abs(deltaY)) {
                targetCol += deltaX > 0 ? 1 : -1;
            } else {
                targetRow += deltaY > 0 ? 1 : -1;
            }

            if (this.isValidPosition(targetRow, targetCol)) {
                this.trySwap(this.touchStartCell.row, this.touchStartCell.col, targetRow, targetCol);
            }
            this.touchStartCell = null;
        }
    }

    handleClick(e) {
        if (this.isAnimating) return;

        // Only handle click if not a drag
        const cell = this.getCellFromEvent(e);
        if (cell && this.touchStartCell) {
            const deltaX = Math.abs(e.clientX - this.touchStartX);
            const deltaY = Math.abs(e.clientY - this.touchStartY);

            if (deltaX < this.SWIPE_THRESHOLD && deltaY < this.SWIPE_THRESHOLD) {
                this.handleCellSelect(cell.row, cell.col);
            }
        }
        this.touchStartCell = null;
    }

    handleCellSelect(row, col) {
        if (!this.board[row][col]) return;

        if (this.selectedCell) {
            // Check if adjacent
            if (this.areAdjacent(this.selectedCell.row, this.selectedCell.col, row, col)) {
                this.trySwap(this.selectedCell.row, this.selectedCell.col, row, col);
            }

            // Deselect
            const prevCell = this.boardElement.children[this.selectedCell.row * this.BOARD_SIZE + this.selectedCell.col];
            prevCell?.classList.remove('selected');
            this.selectedCell = null;
        } else {
            // Select this cell
            this.selectedCell = { row, col };
            const cellElement = this.boardElement.children[row * this.BOARD_SIZE + col];
            cellElement?.classList.add('selected');
        }
    }

    areAdjacent(row1, col1, row2, col2) {
        return (Math.abs(row1 - row2) === 1 && col1 === col2) ||
               (Math.abs(col1 - col2) === 1 && row1 === row2);
    }

    isValidPosition(row, col) {
        return row >= 0 && row < this.BOARD_SIZE && col >= 0 && col < this.BOARD_SIZE;
    }

    // Try to swap two cells
    async trySwap(row1, col1, row2, col2) {
        if (this.isAnimating) return;
        this.isAnimating = true;

        // Clear selection
        if (this.selectedCell) {
            const prevCell = this.boardElement.children[this.selectedCell.row * this.BOARD_SIZE + this.selectedCell.col];
            prevCell?.classList.remove('selected');
            this.selectedCell = null;
        }

        // Perform swap
        this.swap(row1, col1, row2, col2);
        await this.animateSwap(row1, col1, row2, col2);

        // Check for matches
        const matches = this.findAllMatches();

        if (matches.length > 0 || this.checkSpecialCombination(row1, col1, row2, col2)) {
            // Valid move
            this.moves--;
            this.updateUI();

            // Handle special combinations first
            if (this.checkSpecialCombination(row1, col1, row2, col2)) {
                await this.handleSpecialCombination(row1, col1, row2, col2);
            }

            // Process matches
            await this.processMatches();

            // Check game state
            this.checkGameState();
        } else {
            // Invalid move - swap back
            this.swap(row1, col1, row2, col2);
            await this.animateSwap(row1, col1, row2, col2);
        }

        this.isAnimating = false;
    }

    swap(row1, col1, row2, col2) {
        const temp = this.board[row1][col1];
        this.board[row1][col1] = this.board[row2][col2];
        this.board[row2][col2] = temp;
    }

    async animateSwap(row1, col1, row2, col2) {
        const cell1 = this.boardElement.children[row1 * this.BOARD_SIZE + col1];
        const cell2 = this.boardElement.children[row2 * this.BOARD_SIZE + col2];

        cell1?.classList.add('swapping');
        cell2?.classList.add('swapping');

        this.updateCell(row1, col1);
        this.updateCell(row2, col2);

        await this.delay(200);

        cell1?.classList.remove('swapping');
        cell2?.classList.remove('swapping');
    }

    // Find all matches on the board
    findAllMatches() {
        const matches = [];
        const checked = new Set();

        for (let row = 0; row < this.BOARD_SIZE; row++) {
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                if (!this.board[row][col]) continue;

                // Check horizontal match
                const hMatch = this.getHorizontalMatch(row, col);
                if (hMatch.length >= 3) {
                    hMatch.forEach(pos => checked.add(`${pos.row},${pos.col}`));
                    matches.push({ cells: hMatch, direction: 'horizontal' });
                }

                // Check vertical match
                const vMatch = this.getVerticalMatch(row, col);
                if (vMatch.length >= 3) {
                    vMatch.forEach(pos => checked.add(`${pos.row},${pos.col}`));
                    matches.push({ cells: vMatch, direction: 'vertical' });
                }
            }
        }

        // Merge overlapping matches for special candy detection
        return this.mergeMatches(matches);
    }

    getHorizontalMatch(row, col) {
        const color = this.board[row][col]?.color;
        if (!color) return [];

        const match = [{ row, col }];

        // Check left
        for (let c = col - 1; c >= 0; c--) {
            if (this.board[row][c]?.color === color) {
                match.unshift({ row, col: c });
            } else break;
        }

        // Check right
        for (let c = col + 1; c < this.BOARD_SIZE; c++) {
            if (this.board[row][c]?.color === color) {
                match.push({ row, col: c });
            } else break;
        }

        return match;
    }

    getVerticalMatch(row, col) {
        const color = this.board[row][col]?.color;
        if (!color) return [];

        const match = [{ row, col }];

        // Check up
        for (let r = row - 1; r >= 0; r--) {
            if (this.board[r]?.[col]?.color === color) {
                match.unshift({ row: r, col });
            } else break;
        }

        // Check down
        for (let r = row + 1; r < this.BOARD_SIZE; r++) {
            if (this.board[r]?.[col]?.color === color) {
                match.push({ row: r, col });
            } else break;
        }

        return match;
    }

    // Merge overlapping matches to detect L, T shapes
    mergeMatches(matches) {
        const merged = [];
        const used = new Set();

        for (let i = 0; i < matches.length; i++) {
            if (used.has(i)) continue;

            const current = { ...matches[i], cells: [...matches[i].cells] };

            for (let j = i + 1; j < matches.length; j++) {
                if (used.has(j)) continue;

                // Check for intersection
                const intersection = current.cells.some(c1 =>
                    matches[j].cells.some(c2 => c1.row === c2.row && c1.col === c2.col)
                );

                if (intersection) {
                    // Merge
                    matches[j].cells.forEach(cell => {
                        if (!current.cells.some(c => c.row === cell.row && c.col === cell.col)) {
                            current.cells.push(cell);
                        }
                    });
                    current.direction = 'both';
                    used.add(j);
                }
            }

            merged.push(current);
        }

        return merged;
    }

    // Process all matches and create special candies
    async processMatches() {
        this.comboCount = 0;

        while (true) {
            const matches = this.findAllMatches();
            if (matches.length === 0) break;

            this.comboCount++;
            if (this.comboCount > 1) {
                this.showCombo(this.comboCount);
            }

            // Process each match
            for (const match of matches) {
                await this.processMatch(match);
            }

            // Wait for animations
            await this.delay(300);

            // Apply gravity
            await this.applyGravity();

            // Fill empty cells
            await this.fillEmptyCells();

            await this.delay(200);
        }
    }

    async processMatch(match) {
        const cells = match.cells;
        const color = this.board[cells[0].row]?.[cells[0].col]?.color;

        // Calculate score
        const baseScore = cells.length * 10;
        const comboMultiplier = Math.pow(1.5, this.comboCount - 1);
        const points = Math.floor(baseScore * comboMultiplier);
        this.score += points;
        this.updateUI();

        // Show score popup at match center
        const centerCell = cells[Math.floor(cells.length / 2)];
        this.showScorePopup(centerCell.row, centerCell.col, points);

        // Determine special candy creation
        let specialCell = null;
        let specialType = this.SPECIAL.NONE;

        if (cells.length >= 5 && match.direction !== 'both') {
            // Color bomb for 5+ in a line
            specialType = this.SPECIAL.COLOR_BOMB;
            specialCell = cells[Math.floor(cells.length / 2)];
        } else if (cells.length >= 5 || (cells.length >= 5 && match.direction === 'both')) {
            // Wrapped candy for L or T shape (5+ cells in both directions)
            specialType = this.SPECIAL.WRAPPED;
            // Find intersection point
            specialCell = this.findIntersection(cells, match) || cells[0];
        } else if (match.direction === 'both' && cells.length >= 5) {
            // L or T shape - wrapped candy
            specialType = this.SPECIAL.WRAPPED;
            specialCell = this.findIntersection(cells, match) || cells[0];
        } else if (cells.length === 4) {
            // Striped candy for 4 in a row
            specialType = match.direction === 'horizontal' ? this.SPECIAL.STRIPED_V : this.SPECIAL.STRIPED_H;
            specialCell = cells[Math.floor(cells.length / 2)];
        }

        // First check if any cells have special candies that need to activate
        for (const cell of cells) {
            const slime = this.board[cell.row]?.[cell.col];
            if (slime && slime.special !== this.SPECIAL.NONE) {
                await this.activateSpecial(cell.row, cell.col, slime.special, slime.color);
            }
        }

        // Animate match removal
        for (const cell of cells) {
            const index = cell.row * this.BOARD_SIZE + cell.col;
            const cellElement = this.boardElement.children[index];
            const slimeElement = cellElement?.querySelector('.slime');
            slimeElement?.classList.add('matching');
        }

        await this.delay(300);

        // Remove matched cells
        for (const cell of cells) {
            this.board[cell.row][cell.col] = null;
        }

        // Create special candy if applicable
        if (specialCell && specialType !== this.SPECIAL.NONE) {
            this.board[specialCell.row][specialCell.col] = {
                color: color,
                special: specialType
            };
        }

        this.renderBoard();
    }

    findIntersection(cells, match) {
        // For L/T shapes, find the cell that appears in both directions
        const rowCounts = {};
        const colCounts = {};

        cells.forEach(c => {
            rowCounts[c.row] = (rowCounts[c.row] || 0) + 1;
            colCounts[c.col] = (colCounts[c.col] || 0) + 1;
        });

        for (const cell of cells) {
            if (rowCounts[cell.row] > 1 && colCounts[cell.col] > 1) {
                return cell;
            }
        }

        return null;
    }

    // Check if swapping two special candies
    checkSpecialCombination(row1, col1, row2, col2) {
        const slime1 = this.board[row1]?.[col1];
        const slime2 = this.board[row2]?.[col2];

        if (!slime1 || !slime2) return false;

        return (slime1.special !== this.SPECIAL.NONE && slime2.special !== this.SPECIAL.NONE) ||
               (slime1.special === this.SPECIAL.COLOR_BOMB) ||
               (slime2.special === this.SPECIAL.COLOR_BOMB);
    }

    // Handle special candy combinations
    async handleSpecialCombination(row1, col1, row2, col2) {
        const slime1 = this.board[row1][col1];
        const slime2 = this.board[row2][col2];

        if (!slime1 || !slime2) return;

        // Color bomb + anything
        if (slime1.special === this.SPECIAL.COLOR_BOMB && slime2.special === this.SPECIAL.COLOR_BOMB) {
            // Double color bomb - clear entire board
            await this.clearEntireBoard();
            return;
        }

        if (slime1.special === this.SPECIAL.COLOR_BOMB) {
            await this.activateColorBomb(row1, col1, slime2.color, slime2.special);
            return;
        }

        if (slime2.special === this.SPECIAL.COLOR_BOMB) {
            await this.activateColorBomb(row2, col2, slime1.color, slime1.special);
            return;
        }

        // Striped + Striped = cross explosion
        if ((slime1.special === this.SPECIAL.STRIPED_H || slime1.special === this.SPECIAL.STRIPED_V) &&
            (slime2.special === this.SPECIAL.STRIPED_H || slime2.special === this.SPECIAL.STRIPED_V)) {
            await this.crossExplosion(row1, col1);
            return;
        }

        // Wrapped + Wrapped = large explosion
        if (slime1.special === this.SPECIAL.WRAPPED && slime2.special === this.SPECIAL.WRAPPED) {
            await this.largeExplosion(row1, col1, 4);
            return;
        }

        // Striped + Wrapped = 3x line clear
        if ((slime1.special === this.SPECIAL.WRAPPED &&
            (slime2.special === this.SPECIAL.STRIPED_H || slime2.special === this.SPECIAL.STRIPED_V)) ||
            (slime2.special === this.SPECIAL.WRAPPED &&
            (slime1.special === this.SPECIAL.STRIPED_H || slime1.special === this.SPECIAL.STRIPED_V))) {
            await this.giantCrossExplosion(row1, col1);
            return;
        }
    }

    // Activate a special candy
    async activateSpecial(row, col, special, color) {
        switch (special) {
            case this.SPECIAL.STRIPED_H:
                await this.clearRow(row, col);
                break;
            case this.SPECIAL.STRIPED_V:
                await this.clearColumn(row, col);
                break;
            case this.SPECIAL.WRAPPED:
                await this.wrappedExplosion(row, col);
                break;
            case this.SPECIAL.COLOR_BOMB:
                // Find the most common color on board
                const targetColor = this.getMostCommonColor();
                await this.activateColorBomb(row, col, targetColor, this.SPECIAL.NONE);
                break;
        }
    }

    async clearRow(row, sourceCol) {
        const points = this.BOARD_SIZE * 10;
        this.score += points;
        this.updateUI();

        // Visual effect
        this.showLineExplosion(row, sourceCol, 'horizontal');

        for (let col = 0; col < this.BOARD_SIZE; col++) {
            const slime = this.board[row][col];
            if (slime && slime.special !== this.SPECIAL.NONE && col !== sourceCol) {
                // Chain reaction
                await this.activateSpecial(row, col, slime.special, slime.color);
            }
            this.board[row][col] = null;
        }

        this.renderBoard();
        await this.delay(200);
    }

    async clearColumn(sourceRow, col) {
        const points = this.BOARD_SIZE * 10;
        this.score += points;
        this.updateUI();

        // Visual effect
        this.showLineExplosion(sourceRow, col, 'vertical');

        for (let row = 0; row < this.BOARD_SIZE; row++) {
            const slime = this.board[row][col];
            if (slime && slime.special !== this.SPECIAL.NONE && row !== sourceRow) {
                // Chain reaction
                await this.activateSpecial(row, col, slime.special, slime.color);
            }
            this.board[row][col] = null;
        }

        this.renderBoard();
        await this.delay(200);
    }

    async wrappedExplosion(centerRow, centerCol) {
        const points = 9 * 15; // 3x3 area
        this.score += points;
        this.updateUI();

        // Show explosion effect
        this.showExplosion(centerRow, centerCol, '#feca57');

        // Clear 3x3 area
        for (let r = centerRow - 1; r <= centerRow + 1; r++) {
            for (let c = centerCol - 1; c <= centerCol + 1; c++) {
                if (this.isValidPosition(r, c)) {
                    const slime = this.board[r][c];
                    if (slime && slime.special !== this.SPECIAL.NONE &&
                        !(r === centerRow && c === centerCol)) {
                        await this.activateSpecial(r, c, slime.special, slime.color);
                    }
                    this.board[r][c] = null;
                }
            }
        }

        this.renderBoard();
        await this.delay(300);
    }

    async crossExplosion(row, col) {
        await this.clearRow(row, col);
        await this.clearColumn(row, col);
    }

    async giantCrossExplosion(row, col) {
        const points = this.BOARD_SIZE * 6 * 10;
        this.score += points;
        this.updateUI();

        // Clear 3 rows and 3 columns
        for (let r = row - 1; r <= row + 1; r++) {
            if (r >= 0 && r < this.BOARD_SIZE) {
                for (let c = 0; c < this.BOARD_SIZE; c++) {
                    if (this.board[r][c]) {
                        this.board[r][c] = null;
                    }
                }
            }
        }

        for (let c = col - 1; c <= col + 1; c++) {
            if (c >= 0 && c < this.BOARD_SIZE) {
                for (let r = 0; r < this.BOARD_SIZE; r++) {
                    if (this.board[r][c]) {
                        this.board[r][c] = null;
                    }
                }
            }
        }

        this.showExplosion(row, col, '#ff6b6b');
        this.renderBoard();
        await this.delay(400);
    }

    async largeExplosion(row, col, radius) {
        const points = (radius * 2 + 1) * (radius * 2 + 1) * 10;
        this.score += points;
        this.updateUI();

        for (let r = row - radius; r <= row + radius; r++) {
            for (let c = col - radius; c <= col + radius; c++) {
                if (this.isValidPosition(r, c)) {
                    this.board[r][c] = null;
                }
            }
        }

        this.showExplosion(row, col, '#a55eea');
        this.renderBoard();
        await this.delay(400);
    }

    async activateColorBomb(row, col, targetColor, convertToSpecial) {
        const points = 200;
        this.score += points;
        this.updateUI();

        // Clear all candies of the target color
        const cellsToClear = [];

        for (let r = 0; r < this.BOARD_SIZE; r++) {
            for (let c = 0; c < this.BOARD_SIZE; c++) {
                if (this.board[r][c]?.color === targetColor) {
                    cellsToClear.push({ row: r, col: c });
                }
            }
        }

        // If combined with a special candy, convert all matching colors to that special
        if (convertToSpecial !== this.SPECIAL.NONE) {
            for (const cell of cellsToClear) {
                if (this.board[cell.row][cell.col]) {
                    this.board[cell.row][cell.col].special = convertToSpecial;
                }
            }
            this.renderBoard();
            await this.delay(300);

            // Activate all converted specials
            for (const cell of cellsToClear) {
                if (this.board[cell.row][cell.col]) {
                    await this.activateSpecial(cell.row, cell.col, convertToSpecial, targetColor);
                }
            }
        } else {
            // Just clear all matching colors
            for (const cell of cellsToClear) {
                this.board[cell.row][cell.col] = null;
            }
        }

        // Clear the color bomb itself
        this.board[row][col] = null;

        this.showExplosion(row, col, '#feca57');
        this.renderBoard();
        await this.delay(400);
    }

    async clearEntireBoard() {
        const points = this.BOARD_SIZE * this.BOARD_SIZE * 20;
        this.score += points;
        this.updateUI();

        // Dramatic effect - clear from center outward
        const center = Math.floor(this.BOARD_SIZE / 2);

        for (let radius = 0; radius <= this.BOARD_SIZE; radius++) {
            for (let r = 0; r < this.BOARD_SIZE; r++) {
                for (let c = 0; c < this.BOARD_SIZE; c++) {
                    const dist = Math.max(Math.abs(r - center), Math.abs(c - center));
                    if (dist === radius) {
                        this.board[r][c] = null;
                    }
                }
            }
            this.renderBoard();
            await this.delay(50);
        }

        this.showExplosion(center, center, '#ff6b6b');
        await this.delay(300);
    }

    getMostCommonColor() {
        const colorCounts = {};

        for (let r = 0; r < this.BOARD_SIZE; r++) {
            for (let c = 0; c < this.BOARD_SIZE; c++) {
                const color = this.board[r][c]?.color;
                if (color) {
                    colorCounts[color] = (colorCounts[color] || 0) + 1;
                }
            }
        }

        let maxCount = 0;
        let mostCommon = this.COLORS[0];

        for (const [color, count] of Object.entries(colorCounts)) {
            if (count > maxCount) {
                maxCount = count;
                mostCommon = color;
            }
        }

        return mostCommon;
    }

    // Apply gravity - candies fall down
    async applyGravity() {
        let moved = false;

        for (let col = 0; col < this.BOARD_SIZE; col++) {
            let emptyRow = this.BOARD_SIZE - 1;

            for (let row = this.BOARD_SIZE - 1; row >= 0; row--) {
                if (this.board[row][col]) {
                    if (row !== emptyRow) {
                        this.board[emptyRow][col] = this.board[row][col];
                        this.board[row][col] = null;
                        moved = true;
                    }
                    emptyRow--;
                }
            }
        }

        if (moved) {
            this.renderBoard();

            // Add falling animation class
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                for (let row = 0; row < this.BOARD_SIZE; row++) {
                    if (this.board[row][col]) {
                        const index = row * this.BOARD_SIZE + col;
                        const cell = this.boardElement.children[index];
                        const slime = cell?.querySelector('.slime');
                        slime?.classList.add('falling');
                    }
                }
            }

            await this.delay(300);
        }
    }

    // Fill empty cells with new candies
    async fillEmptyCells() {
        let filled = false;

        for (let col = 0; col < this.BOARD_SIZE; col++) {
            for (let row = 0; row < this.BOARD_SIZE; row++) {
                if (!this.board[row][col]) {
                    this.board[row][col] = {
                        color: this.getRandomColor(),
                        special: this.SPECIAL.NONE
                    };
                    filled = true;
                }
            }
        }

        if (filled) {
            this.renderBoard();

            // Add falling animation
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                for (let row = 0; row < this.BOARD_SIZE; row++) {
                    const index = row * this.BOARD_SIZE + col;
                    const cell = this.boardElement.children[index];
                    const slime = cell?.querySelector('.slime');
                    slime?.classList.add('falling');
                }
            }

            await this.delay(300);
        }
    }

    // Visual effects
    showScorePopup(row, col, points) {
        const cell = this.boardElement.children[row * this.BOARD_SIZE + col];
        if (!cell) return;

        const popup = document.createElement('div');
        popup.className = 'score-popup';
        popup.textContent = `+${points}`;

        const rect = cell.getBoundingClientRect();
        const boardRect = this.boardElement.getBoundingClientRect();

        popup.style.left = (rect.left - boardRect.left + rect.width / 2) + 'px';
        popup.style.top = (rect.top - boardRect.top) + 'px';

        this.boardElement.appendChild(popup);

        setTimeout(() => popup.remove(), 1000);
    }

    showExplosion(row, col, color) {
        const cell = this.boardElement.children[row * this.BOARD_SIZE + col];
        if (!cell) return;

        const explosion = document.createElement('div');
        explosion.className = 'explosion';
        explosion.style.background = color;
        explosion.style.width = '100%';
        explosion.style.height = '100%';

        cell.appendChild(explosion);

        setTimeout(() => explosion.remove(), 500);
    }

    showLineExplosion(row, col, direction) {
        const cell = this.boardElement.children[row * this.BOARD_SIZE + col];
        if (!cell) return;

        const line = document.createElement('div');
        line.className = `line-explosion ${direction}`;

        if (direction === 'horizontal') {
            line.style.width = '800%';
            line.style.left = '-350%';
            line.style.top = '45%';
        } else {
            line.style.height = '800%';
            line.style.top = '-350%';
            line.style.left = '45%';
        }

        cell.appendChild(line);

        setTimeout(() => line.remove(), 400);
    }

    showCombo(count) {
        this.comboDisplay.textContent = `${count}x COMBO!`;
        this.comboDisplay.classList.remove('active');
        void this.comboDisplay.offsetWidth; // Trigger reflow
        this.comboDisplay.classList.add('active');
    }

    // UI Updates
    updateUI() {
        this.scoreElement.textContent = this.score.toLocaleString();
        this.movesElement.textContent = this.moves;
        this.levelElement.textContent = this.level;

        // Warning for low moves
        if (this.moves <= 5) {
            this.movesElement.classList.add('moves-warning');
        } else {
            this.movesElement.classList.remove('moves-warning');
        }
    }

    // Check win/lose conditions
    checkGameState() {
        if (this.score >= this.targetScore) {
            this.showLevelComplete();
        } else if (this.moves <= 0) {
            this.showGameOver();
        } else if (!this.hasValidMoves()) {
            this.shuffleBoard();
        }
    }

    hasValidMoves() {
        for (let row = 0; row < this.BOARD_SIZE; row++) {
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                // Check right swap
                if (col < this.BOARD_SIZE - 1) {
                    this.swap(row, col, row, col + 1);
                    const hasMatch = this.findAllMatches().length > 0;
                    this.swap(row, col, row, col + 1);
                    if (hasMatch) return true;
                }

                // Check down swap
                if (row < this.BOARD_SIZE - 1) {
                    this.swap(row, col, row + 1, col);
                    const hasMatch = this.findAllMatches().length > 0;
                    this.swap(row, col, row + 1, col);
                    if (hasMatch) return true;
                }
            }
        }
        return false;
    }

    shuffleBoard() {
        // Collect all current candies
        const candies = [];
        for (let row = 0; row < this.BOARD_SIZE; row++) {
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                if (this.board[row][col]) {
                    candies.push(this.board[row][col]);
                }
            }
        }

        // Fisher-Yates shuffle
        for (let i = candies.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [candies[i], candies[j]] = [candies[j], candies[i]];
        }

        // Replace on board
        let index = 0;
        for (let row = 0; row < this.BOARD_SIZE; row++) {
            for (let col = 0; col < this.BOARD_SIZE; col++) {
                this.board[row][col] = candies[index++];
            }
        }

        this.renderBoard();

        // If still no moves, create new board
        if (!this.hasValidMoves()) {
            this.createBoard();
            this.renderBoard();
        }
    }

    showLevelComplete() {
        document.getElementById('final-score').textContent = this.score.toLocaleString();
        document.getElementById('level-complete').classList.add('active');
    }

    showGameOver() {
        document.getElementById('gameover-score').textContent = this.score.toLocaleString();
        document.getElementById('game-over').classList.add('active');
    }

    nextLevel() {
        document.getElementById('level-complete').classList.remove('active');
        this.level++;
        this.moves = 30 + (this.level * 2);
        this.targetScore = 1000 + (this.level * 500);
        this.createBoard();
        this.renderBoard();
        this.updateUI();
    }

    resetGame() {
        document.getElementById('level-complete').classList.remove('active');
        document.getElementById('game-over').classList.remove('active');
        this.score = 0;
        this.moves = 30;
        this.level = 1;
        this.targetScore = 1000;
        this.selectedCell = null;
        this.isAnimating = false;
        this.createBoard();
        this.renderBoard();
        this.updateUI();
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Initialize game
const game = new SlimeCrush();
