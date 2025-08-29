// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { getFirestore } from "firebase-admin/firestore";
import { logger } from "./logger";

/**
 * Defines the interface for a cache service.
 */
export interface ICacheService {
  setSessionCache(
    sessionId: string,
    catalog: Record<string, unknown>
  ): Promise<void>;
  getSessionCache(sessionId: string): Promise<Record<string, unknown> | null>;
}

/**
 * Defines the shape of the context object for flows.
 */
export interface CacheFlowContext {
  cache?: ICacheService;
}

/**
 * A cache service that uses Firestore for storage.
 */
class FirestoreCacheService implements ICacheService {
  private db = getFirestore();
  private sessionCollection = this.db.collection("sessions");

  constructor() {
    this.db.settings({
      ignoreUndefinedProperties: true,
      databaseId: "genui-sdk-sessions",
    });
  }

  async setSessionCache(
    sessionId: string,
    catalog: Record<string, unknown>
  ): Promise<void> {
    logger.debug(`Storing catalog in Firestore for session ID: ${sessionId}`);
    await this.sessionCollection.doc(sessionId).set({ catalog });
  }

  async getSessionCache(
    sessionId: string
  ): Promise<Record<string, unknown> | null> {
    logger.debug(
      `Retrieving catalog from Firestore for session ID: ${sessionId}`
    );
    const doc = await this.sessionCollection.doc(sessionId).get();
    if (!doc.exists) {
      logger.warn(`No session document found for ID: ${sessionId}`);
      return null;
    }
    return doc.data()?.catalog as Record<string, unknown> | null;
  }
}

// Export a singleton instance for the main application to use.
export const cacheService: ICacheService = new FirestoreCacheService();
