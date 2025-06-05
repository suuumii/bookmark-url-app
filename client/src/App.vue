<script setup lang="ts">
import { ref } from 'vue';

// 型定義
interface Bookmark {
  id: string;
  title: string;
  url: string;
}

// 状態管理
interface EditState {
  id: string;
  title: string;
  url: string;
}

// 定数
const DIALOG_STATES = {
  NORMAL: 'normal',
  EDITING: 'editing',
  DELETING: 'deleting',
} as const;

// API設定
const API_BASE_URL = 'http://localhost:3000';
const API_ENDPOINTS = '/api/bookmarks';

// リアクティブな状態
const bookmarks = ref<Bookmark[]>([]);
const currentState = ref<typeof DIALOG_STATES[keyof typeof DIALOG_STATES]>(DIALOG_STATES.NORMAL);
const editState = ref<EditState>({
  id: '',
  title: '',
  url: '',
});
const deleteTargetId = ref<string>('');
const isLoading = ref<boolean>(false);
const error = ref<string | null>(null);

// メソッド
const fetchBookmarks = async () => {
  try {
    isLoading.value = true;
    error.value = null;
    const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS}`);
    if (!response.ok) {
      throw new Error('ブックマークの取得に失敗しました');
    }
    const data = await response.json();
    bookmarks.value = data.bookmarks;
  } catch (e) {
    error.value = e instanceof Error ? e.message : '予期せぬエラーが発生しました';
  } finally {
    isLoading.value = false;
  }
};

const addBookmark = async () => {
  try {
    const [tab] = await chrome.tabs.query({
      active: true,
      lastFocusedWindow: true,
    });
    const decodedUrl = decodeURI(tab.url);

    isLoading.value = true;
    error.value = null;
    const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        bookmark_title: tab.title,
        bookmark_url: decodedUrl,
      }),
    });

    if (!response.ok) {
      throw new Error('ブックマークの追加に失敗しました');
    }

    await fetchBookmarks();
  } catch (e) {
    error.value = e instanceof Error ? e.message : '予期せぬエラーが発生しました';
  } finally {
    isLoading.value = false;
  }
};

const startEdit = (bookmark: Bookmark) => {
  editState.value = {
    id: bookmark.id,
    title: bookmark.title,
    url: bookmark.url,
  };
  currentState.value = DIALOG_STATES.EDITING;
};

const startDelete = (bookmark: Bookmark) => {
  deleteTargetId.value = bookmark.id;
  currentState.value = DIALOG_STATES.DELETING;
};

const saveEdit = async () => {
  try {
    isLoading.value = true;
    error.value = null;
    const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        bookmark_id: editState.value.id,
        bookmark_title: editState.value.title,
        bookmark_url: editState.value.url,
      }),
    });

    if (!response.ok) {
      throw new Error('ブックマークの更新に失敗しました');
    }

    currentState.value = DIALOG_STATES.NORMAL;
    await fetchBookmarks();
  } catch (e) {
    error.value = e instanceof Error ? e.message : '予期せぬエラーが発生しました';
  } finally {
    isLoading.value = false;
  }
};

const cancelEdit = () => {
  currentState.value = DIALOG_STATES.NORMAL;
};

const confirmDelete = async () => {
  try {
    isLoading.value = true;
    error.value = null;
    const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        bookmark_id: editState.value.id,
      }),
    });

    if (!response.ok) {
      throw new Error('ブックマークの削除に失敗しました');
    }

    currentState.value = DIALOG_STATES.NORMAL;
    await fetchBookmarks();
  } catch (e) {
    error.value = e instanceof Error ? e.message : '予期せぬエラーが発生しました';
  } finally {
    isLoading.value = false;
  }
};

const cancelDelete = () => {
  currentState.value = DIALOG_STATES.NORMAL;
};

// 初期データ取得
fetchBookmarks();
</script>

<template>
  <v-app class="app">
    <v-container>
      <header class="header">
        <p>Bookmarks</p>
        <v-divider />
        <v-btn color="grey-darken-3" class="add-button" elevation="0" @click="addBookmark()" :disabled="isLoading">
          <v-icon>mdi-plus</v-icon>
        </v-btn>
      </header>
      <main class="main">
        <!-- エラーメッセージ -->
        <v-alert v-if="error" type="error" class="mb-4">
          {{ error }}
          <template v-slot:append>
            <v-btn color="error" variant="text" @click="error = null">
              閉じる
            </v-btn>
          </template>
        </v-alert>

        <!-- ローディング -->
        <div v-if="isLoading" class="loading-overlay">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
        </div>

        <div v-for="bookmark in bookmarks" :key="bookmark.id" class="bookmark-item">
          <!-- 編集モード -->
          <div v-if="currentState === DIALOG_STATES.EDITING && editState.id === bookmark.id" class="edit-form">
            <v-text-field v-model="editState.title" label="タイトル" variant="outlined" density="compact"
              :disabled="isLoading"></v-text-field>
            <v-text-field v-model="editState.url" label="URL" variant="outlined" density="compact"
              :disabled="isLoading"></v-text-field>
            <div class="edit-actions">
              <v-btn color="grey-darken-2" variant="text" size="small" class="action-button" @click="cancelEdit"
                :disabled="isLoading">
                キャンセル
              </v-btn>
              <v-btn color="grey-lighten-1" variant="text" size="small" class="action-button" @click="saveEdit"
                :disabled="isLoading">
                保存
              </v-btn>
            </div>
          </div>

          <!-- 削除確認モード -->
          <div v-else-if="currentState === DIALOG_STATES.DELETING && deleteTargetId === bookmark.id"
            class="delete-confirm">
            <div class="delete-info">
              <p class="delete-title">{{ bookmark.title }}</p>
              <p class="delete-url">{{ bookmark.url }}</p>
            </div>
            <p class="delete-message">このブックマークを削除してもよろしいですか？</p>
            <div class="delete-actions">
              <v-btn color="grey-darken-2" variant="text" size="small" class="action-button" @click="cancelDelete"
                :disabled="isLoading">
                キャンセル
              </v-btn>
              <v-btn color="error" variant="text" size="small" class="action-button delete-button"
                @click="confirmDelete" :disabled="isLoading">
                削除
              </v-btn>
            </div>
          </div>

          <!-- 通常表示モード -->
          <div v-else class="bookmark-content">
            <a :href="bookmark.url" target="_blank" rel="noopener noreferrer">{{ bookmark.title }}</a>
            <div class="bookmark-actions">
              <v-btn icon size="small" class="icon-button edit-button" @click="startEdit(bookmark)"
                :disabled="isLoading">
                <v-icon>mdi-pencil</v-icon>
              </v-btn>
              <v-btn icon size="small" color="error" class="icon-button" @click="startDelete(bookmark)"
                :disabled="isLoading">
                <v-icon>mdi-delete</v-icon>
              </v-btn>
            </div>
          </div>
        </div>
      </main>
    </v-container>
  </v-app>
</template>

<style scoped>
.app {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 500px;
  background-color: #121212;
  color: #ffffff;
}

.header {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 50px;
  font-size: 20px;
}

.bookmark-item {
  padding: 8px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.bookmark-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.bookmark-actions {
  display: flex;
  gap: 8px;
}

.edit-form,
.delete-confirm {
  padding: 8px 0;
}

.edit-actions,
.delete-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 8px;
}

.delete-info {
  margin-bottom: 8px;
}

.delete-title {
  font-weight: bold;
  margin: 0;
  padding: 4px 0;
}

.delete-url {
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  padding: 4px 0;
  font-size: 0.9em;
}

.delete-message {
  margin: 0;
  padding: 8px 0;
  color: rgba(255, 255, 255, 0.9);
}

a {
  text-decoration: none;
  color: inherit;
}

.add-button {
  background-color: #2c2c2c !important;
  border-radius: 50% !important;
  min-width: 40px !important;
  height: 40px !important;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3) !important;
}

.add-button:hover {
  transform: scale(1.1);
  background-color: #3c3c3c !important;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.4) !important;
}

.add-icon {
  font-size: 24px !important;
  font-weight: 300 !important;
  transform: scale(1.2);
}

.action-button {
  font-weight: 500 !important;
  letter-spacing: 0.5px !important;
  text-transform: none !important;
  transition: all 0.2s ease;
}

.action-button:hover {
  opacity: 0.8;
  background-color: rgba(255, 255, 255, 0.05) !important;
}

.icon-button {
  background-color: transparent !important;
  box-shadow: none !important;
  transition: all 0.2s ease;
}

.icon-button:hover {
  transform: scale(1.1);
  background-color: rgba(255, 255, 255, 0.05) !important;
}

.icon-button :deep(.v-icon) {
  font-size: 20px;
}

.delete-button {
  color: #cf6679 !important;
}

.edit-button :deep(.v-icon) {
  color: white !important;
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}
</style>
