// ============================================
// SYSTÈME DE NOTES EMPLOYÉS
// ============================================

// Stocker les notes pour y accéder facilement
let currentNotes = [];

// Charger les notes de l'entreprise
function loadCompanyNotes() {
    postData('getCompanyNotes', {});
}

window.receiveCompanyNotes = function(notes) {
    currentNotes = notes || [];
    displayNotesOnDashboard(currentNotes);
    displayNotesInAdmin(currentNotes);
};

// Afficher les notes sur le dashboard (max 3)
function displayNotesOnDashboard(notes) {
    const container = document.getElementById('companyNotesContainer');
    if (!container) return;

    if (!notes || notes.length === 0) {
        container.innerHTML = '';
        return;
    }

    let html = '<div style="margin-top: 20px;"><h3 style="color: #e2e8f0; margin-bottom: 15px; font-size: 16px;"><i class="fa-solid fa-sticky-note"></i> Notes de l\'Entreprise</h3>';

    notes.slice(0, 3).forEach(note => {
        const date = new Date(note.created_at).toLocaleDateString('fr-FR');
        const safeTitle = escapeHtml(note.title);
        const safeContent = escapeHtml(note.content);
        const safeCreatedBy = escapeHtml(note.created_by);

        html += `
            <div style="background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%); border: 1px solid #334155; border-left: 4px solid #3b82f6; border-radius: 8px; padding: 15px; margin-bottom: 12px;">
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 8px;">
                    <h4 style="color: #3b82f6; margin: 0; font-size: 15px;">${safeTitle}</h4>
                    <span style="color: #64748b; font-size: 11px;">${date}</span>
                </div>
                <p style="color: #cbd5e1; margin: 0; font-size: 13px; line-height: 1.5; white-space: pre-wrap;">${safeContent}</p>
                <div style="color: #64748b; font-size: 11px; margin-top: 8px;">
                    <i class="fa-solid fa-user"></i> ${safeCreatedBy}
                </div>
            </div>
        `;
    });

    html += '</div>';
    container.innerHTML = html;
}

// Afficher les notes dans l'onglet Administration
function displayNotesInAdmin(notes) {
    const container = document.getElementById('notesList');
    if (!container) return;

    if (!notes || notes.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📝</div><div class="empty-state-text">Aucune note</div></div>';
        return;
    }

    let html = '';
    notes.forEach((note, index) => {
        const date = new Date(note.created_at).toLocaleDateString('fr-FR', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
        const safeTitle = escapeHtml(note.title);
        const safeContent = escapeHtml(note.content);
        const safeCreatedBy = escapeHtml(note.created_by);

        html += `
            <div class="note-item" data-note-index="${index}" style="background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%); border: 1px solid #334155; border-radius: 8px; padding: 15px; margin-bottom: 12px;">
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 10px;">
                    <div style="flex: 1;">
                        <h4 style="color: #3b82f6; margin: 0 0 5px 0; font-size: 16px;">${safeTitle}</h4>
                        <p style="color: #cbd5e1; margin: 0; font-size: 14px; line-height: 1.6; white-space: pre-wrap;">${safeContent}</p>
                    </div>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 10px; padding-top: 10px; border-top: 1px solid #334155;">
                    <div style="color: #64748b; font-size: 12px;">
                        <i class="fa-solid fa-user"></i> ${safeCreatedBy} • ${date}
                    </div>
                    <div style="display: flex; gap: 8px;">
                        <button class="btn-edit-note" data-note-id="${note.id}" data-note-index="${index}"
                                style="background: #3b82f6; border: none; color: white; padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 12px;">
                            <i class="fa-solid fa-edit"></i> Modifier
                        </button>
                        <button class="btn-delete-note" data-note-id="${note.id}"
                                style="background: #dc2626; border: none; color: white; padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 12px;">
                            <i class="fa-solid fa-trash"></i> Supprimer
                        </button>
                    </div>
                </div>
            </div>
        `;
    });

    container.innerHTML = html;

    // Ajouter les event listeners
    container.querySelectorAll('.btn-edit-note').forEach(btn => {
        btn.addEventListener('click', function() {
            const noteIndex = parseInt(this.getAttribute('data-note-index'));
            const note = currentNotes[noteIndex];
            if (note) {
                editNote(note.id, note.title, note.content);
            }
        });
    });

    container.querySelectorAll('.btn-delete-note').forEach(btn => {
        btn.addEventListener('click', function() {
            const noteId = parseInt(this.getAttribute('data-note-id'));
            deleteNote(noteId);
        });
    });
}

// Ajouter ou modifier une note
document.addEventListener('DOMContentLoaded', () => {
    const addNoteBtn = document.getElementById('addNoteBtn');
    if (addNoteBtn) {
        addNoteBtn.addEventListener('click', () => {
            const title = document.getElementById('newNoteTitle').value.trim();
            const content = document.getElementById('newNoteContent').value.trim();

            if (!title || !content) {
                return; // Validation silencieuse (pas d'alert qui freeze)
            }

            const editingId = addNoteBtn.getAttribute('data-editing-id');

            if (editingId) {
                // Mode édition
                postData('updateCompanyNote', { noteId: parseInt(editingId), title, content });

                // Réinitialiser le bouton
                addNoteBtn.innerHTML = '<i class="fa-solid fa-plus"></i> Ajouter une Note';
                addNoteBtn.style.background = '';
                addNoteBtn.removeAttribute('data-editing-id');
            } else {
                // Mode ajout
                postData('addCompanyNote', { title, content });
            }

            // Vider les champs
            document.getElementById('newNoteTitle').value = '';
            document.getElementById('newNoteContent').value = '';
        });
    }
});

// Modifier une note
function editNote(noteId, title, content) {
    // Remplir les champs du formulaire avec les valeurs actuelles
    document.getElementById('newNoteTitle').value = title;
    document.getElementById('newNoteContent').value = content;

    // Changer le bouton pour mode édition
    const addBtn = document.getElementById('addNoteBtn');
    addBtn.innerHTML = '<i class="fa-solid fa-save"></i> Sauvegarder les modifications';
    addBtn.style.background = '#f59e0b';

    // Stocker l'ID de la note en cours d'édition
    addBtn.setAttribute('data-editing-id', noteId);
}

// Supprimer une note (sans confirmation pour éviter le freeze)
function deleteNote(noteId) {
    postData('deleteCompanyNote', { noteId });
}

// Helper pour échapper le HTML
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
